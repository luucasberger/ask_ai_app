import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/widgets/rename_conversation_dialog.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  Conversation buildConversation({
    String id = 'c0',
    String title = 'Original title',
  }) {
    return Conversation(
      id: id,
      title: title,
      createdAt: DateTime.utc(2026, 4, 27),
      updatedAt: DateTime.utc(2026, 4, 27),
    );
  }

  Future<({Future<String?> result, BuildContext context})> openDialog(
    WidgetTester tester, {
    Conversation? conversation,
  }) async {
    final completer = Completer<({Future<String?> result, BuildContext ctx})>();
    await tester.pumpApp(
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              final result = RenameConversationDialog.show(
                context,
                conversation ?? buildConversation(),
              );
              completer.complete((result: result, ctx: context));
            },
            child: const Text('open'),
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final captured = await completer.future;
    return (result: captured.result, context: captured.ctx);
  }

  group(RenameConversationDialog, () {
    testWidgets('renders localized title, hint, and actions', (tester) async {
      final captured = await openDialog(tester);

      final l10n = captured.context.l10n;
      expect(find.text(l10n.renameConversationDialogTitle), findsOneWidget);
      expect(find.text(l10n.renameConversationDialogHint), findsOneWidget);
      expect(find.text(l10n.renameConversationDialogCancel), findsOneWidget);
      expect(find.text(l10n.renameConversationDialogSave), findsOneWidget);

      // Dismiss for clean teardown.
      await tester.tap(find.text(l10n.renameConversationDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('prefills the text field with the current title', (
      tester,
    ) async {
      final captured = await openDialog(
        tester,
        conversation: buildConversation(title: 'Lunch plans'),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Lunch plans');

      await tester.tap(
        find.text(captured.context.l10n.renameConversationDialogCancel),
      );
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Save is disabled when the field is unchanged', (tester) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;

      final saveButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10n.renameConversationDialogSave),
      );
      expect(saveButton.onPressed, isNull);

      await tester.tap(find.text(l10n.renameConversationDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Save is disabled when the trimmed value is empty', (
      tester,
    ) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      final saveButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10n.renameConversationDialogSave),
      );
      expect(saveButton.onPressed, isNull);

      await tester.tap(find.text(l10n.renameConversationDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Cancel pops with null', (tester) async {
      final captured = await openDialog(tester);

      await tester.tap(
        find.text(captured.context.l10n.renameConversationDialogCancel),
      );
      await tester.pumpAndSettle();

      expect(await captured.result, isNull);
    });

    testWidgets('Save pops with the trimmed new title', (tester) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;

      await tester.enterText(find.byType(TextField), '  Updated  ');
      await tester.pump();
      await tester.tap(find.text(l10n.renameConversationDialogSave));
      await tester.pumpAndSettle();

      expect(await captured.result, 'Updated');
    });

    testWidgets('submitting via the keyboard pops with the trimmed title', (
      tester,
    ) async {
      final captured = await openDialog(tester);

      await tester.enterText(find.byType(TextField), '  Submitted  ');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(await captured.result, 'Submitted');
    });

    testWidgets(
      'submitting via the keyboard while Save is disabled is a no-op',
      (tester) async {
        final captured = await openDialog(tester);
        final l10n = captured.context.l10n;

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Dialog still open.
        expect(find.text(l10n.renameConversationDialogTitle), findsOneWidget);

        await tester.tap(find.text(l10n.renameConversationDialogCancel));
        await tester.pumpAndSettle();
        await captured.result;
      },
    );
  });
}
