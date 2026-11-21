import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loomea/data/models/support_model.dart';
import 'package:loomea/data/repositories/loomea_repository.dart';
import 'package:loomea/presentation/features/support/support_chat_page.dart';

class _FakeRepository implements LoomeeaRepository {
  @override
  Future<SupportReply> askSupport(List<SupportMessage> messages, String language) async =>
      messages.last.text.contains('weather')
          ? const SupportReply(aiUsed: true, answered: false)
          : const SupportReply(aiUsed: true, answered: true, answer: 'Tap Cancel.');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('asks a suggested question and a typed one', (tester) async {
    await tester.pumpWidget(RepositoryProvider<LoomeeaRepository>.value(
      value: _FakeRepository(),
      child: const MaterialApp(home: SupportChatPage()),
    ));

    // Strings are not loaded in tests, so translation keys are shown.
    await tester.tap(find.text('support_q_cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Tap Cancel.'), findsOneWidget);
    expect(find.text('support_q_reliability'), findsNothing);

    await tester.enterText(find.byType(TextField), 'weather tomorrow?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('weather tomorrow?'), findsOneWidget);
    expect(find.text('support_no_answer'), findsOneWidget);
  });
}
