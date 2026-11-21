import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/support_model.dart';
import '../../../data/repositories/loomea_repository.dart';

enum SupportEntryKind {
  user,
  answer,

  /// The assistant had no answer in the help articles.
  noAnswer,

  /// The AI could not be reached.
  unavailable,
  rateLimited,
  error,
}

class SupportEntry extends Equatable {
  final SupportEntryKind kind;

  /// The user's message or the assistant's answer; null for notices.
  final String? text;

  const SupportEntry(this.kind, [this.text]);

  @override
  List<Object?> get props => [kind, text];
}

class SupportState extends Equatable {
  final List<SupportEntry> entries;
  final bool sending;

  const SupportState({this.entries = const [], this.sending = false});

  @override
  List<Object?> get props => [entries, sending];
}

class SupportCubit extends Cubit<SupportState> {
  /// Matches the history the backend accepts.
  static const maxHistory = 8;
  static const maxMessageLength = 500;

  final LoomeeaRepository repository;
  final String Function() language;

  SupportCubit({required this.repository, required this.language})
      : super(const SupportState());

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.sending) return;
    final question = message.length > maxMessageLength
        ? message.substring(0, maxMessageLength)
        : message;

    final entries = [
      ...state.entries,
      SupportEntry(SupportEntryKind.user, question),
    ];
    emit(SupportState(entries: entries, sending: true));

    SupportEntry reply;
    try {
      final result = await repository.askSupport(_history(entries), language());
      if (result.rateLimited) {
        reply = const SupportEntry(SupportEntryKind.rateLimited);
      } else if (!result.aiUsed) {
        reply = const SupportEntry(SupportEntryKind.unavailable);
      } else if (result.answered && (result.answer ?? '').trim().isNotEmpty) {
        reply = SupportEntry(SupportEntryKind.answer, result.answer!.trim());
      } else {
        reply = const SupportEntry(SupportEntryKind.noAnswer);
      }
    } catch (_) {
      reply = const SupportEntry(SupportEntryKind.error);
    }
    if (isClosed) return;
    emit(SupportState(entries: [...entries, reply]));
  }

  /// The real conversation (questions and answers), without notices.
  static List<SupportMessage> _history(List<SupportEntry> entries) {
    final messages = entries
        .where((e) =>
            e.kind == SupportEntryKind.user ||
            e.kind == SupportEntryKind.answer)
        .map((e) => SupportMessage(
              role: e.kind == SupportEntryKind.user ? 'user' : 'assistant',
              text: e.text!,
            ))
        .toList();
    return messages.length > maxHistory
        ? messages.sublist(messages.length - maxHistory)
        : messages;
  }
}
