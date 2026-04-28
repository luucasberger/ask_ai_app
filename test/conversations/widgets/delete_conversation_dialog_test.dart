import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/widgets/delete_conversation_dialog.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  Future<({Future<bool> result, BuildContext context})> openDialog(
    WidgetTester tester,
  ) async {
    final completer = Completer<({Future<bool> result, BuildContext ctx})>();
    await tester.pumpApp(
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              final result = DeleteConversationDialog.show(context);
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

  group(DeleteConversationDialog, () {
    testWidgets('renders localized title, body, and actions', (tester) async {
      final captured = await openDialog(tester);

      final l10n = captured.context.l10n;
      expect(find.text(l10n.deleteConversationDialogTitle), findsOneWidget);
      expect(find.text(l10n.deleteConversationDialogBody), findsOneWidget);
      expect(find.text(l10n.deleteConversationDialogCancel), findsOneWidget);
      expect(find.text(l10n.deleteConversationDialogConfirm), findsOneWidget);

      await tester.tap(find.text(l10n.deleteConversationDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Cancel resolves to false', (tester) async {
      final captured = await openDialog(tester);

      await tester.tap(
        find.text(captured.context.l10n.deleteConversationDialogCancel),
      );
      await tester.pumpAndSettle();

      expect(await captured.result, isFalse);
    });

    testWidgets('Delete resolves to true', (tester) async {
      final captured = await openDialog(tester);

      await tester.tap(
        find.text(captured.context.l10n.deleteConversationDialogConfirm),
      );
      await tester.pumpAndSettle();

      expect(await captured.result, isTrue);
    });

    testWidgets('barrier dismiss resolves to false', (tester) async {
      final captured = await openDialog(tester);

      // Tap the modal barrier to dismiss.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(await captured.result, isFalse);
    });
  });
}
