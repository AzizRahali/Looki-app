import 'package:equatable/equatable.dart';

/// One message in a support conversation, as sent to the backend.
class SupportMessage extends Equatable {
  /// "user" or "assistant".
  final String role;
  final String text;

  const SupportMessage({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role, 'text': text};

  @override
  List<Object?> get props => [role, text];
}

class SupportReply extends Equatable {
  /// False when the AI could not be reached.
  final bool aiUsed;

  /// True only when [answer] comes from the help articles.
  final bool answered;
  final String? answer;
  final bool rateLimited;

  const SupportReply({
    required this.aiUsed,
    required this.answered,
    this.answer,
    this.rateLimited = false,
  });

  factory SupportReply.fromJson(Map<String, dynamic> json) => SupportReply(
        aiUsed: json['aiUsed'] as bool? ?? false,
        answered: json['answered'] as bool? ?? false,
        answer: json['answer'] as String?,
        rateLimited: json['rateLimited'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [aiUsed, answered, answer, rateLimited];
}
