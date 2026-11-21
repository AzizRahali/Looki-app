import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:loomea/data/models/support_model.dart';
import 'package:loomea/data/repositories/loomea_repository.dart';
import 'package:loomea/logic/blocs/support/support_cubit.dart';

class _FakeRepository implements LoomeeaRepository {
  final requests = <List<SupportMessage>>[];
  final replies = <Completer<SupportReply>>[];

  @override
  Future<SupportReply> askSupport(List<SupportMessage> messages, String language) {
    requests.add(messages);
    final completer = Completer<SupportReply>();
    replies.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('sends the conversation without notices and shows the answer', () async {
    final repository = _FakeRepository();
    final cubit = SupportCubit(repository: repository, language: () => 'fr');

    cubit.send('Q1');
    await _settle();
    repository.replies.last.complete(const SupportReply(aiUsed: true, answered: false));
    await _settle();
    cubit.send('Q2');
    await _settle();
    expect(cubit.state.sending, isTrue);
    repository.replies.last
        .complete(const SupportReply(aiUsed: true, answered: true, answer: 'A2'));
    await _settle();

    // The "no answer" notice is not sent back as an assistant message.
    expect(repository.requests.last.map((m) => '${m.role}:${m.text}'),
        ['user:Q1', 'user:Q2']);
    expect(cubit.state.entries.map((e) => e.kind), [
      SupportEntryKind.user,
      SupportEntryKind.noAnswer,
      SupportEntryKind.user,
      SupportEntryKind.answer,
    ]);
    expect(cubit.state.sending, isFalse);
    await cubit.close();
  });

  test('ignores new messages while waiting and maps failures to notices', () async {
    final repository = _FakeRepository();
    final cubit = SupportCubit(repository: repository, language: () => 'en');

    cubit.send('Q1');
    await _settle();
    cubit.send('Q2');
    await _settle();
    expect(repository.requests, hasLength(1));

    repository.replies.last
        .complete(const SupportReply(aiUsed: false, answered: false, rateLimited: true));
    await _settle();
    expect(cubit.state.entries.last.kind, SupportEntryKind.rateLimited);

    cubit.send('Q3');
    await _settle();
    repository.replies.last.completeError(Exception('offline'));
    await _settle();
    expect(cubit.state.entries.last.kind, SupportEntryKind.error);
    await cubit.close();
  });
}
