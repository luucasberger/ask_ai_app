import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/widgets/create_folder_dialog.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  Future<({Future<String?> result, BuildContext context})> openDialog(
    WidgetTester tester,
  ) async {
    final completer = Completer<({Future<String?> result, BuildContext ctx})>();
    await tester.pumpApp(
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              final result = CreateFolderDialog.show(context);
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

  group(CreateFolderDialog, () {
    testWidgets('renders localized title, hint, and actions', (tester) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;
      expect(find.text(l10n.createFolderDialogTitle), findsOneWidget);
      expect(find.text(l10n.createFolderDialogHint), findsOneWidget);
      expect(find.text(l10n.createFolderDialogCancel), findsOneWidget);
      expect(find.text(l10n.createFolderDialogCreate), findsOneWidget);

      await tester.tap(find.text(l10n.createFolderDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Create is disabled while the field is empty', (tester) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;

      final create = tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10n.createFolderDialogCreate),
      );
      expect(create.onPressed, isNull);

      await tester.tap(find.text(l10n.createFolderDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Create is disabled when the trimmed value is empty', (
      tester,
    ) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      final create = tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10n.createFolderDialogCreate),
      );
      expect(create.onPressed, isNull);

      await tester.tap(find.text(l10n.createFolderDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Cancel pops with null', (tester) async {
      final captured = await openDialog(tester);
      await tester.tap(
        find.text(captured.context.l10n.createFolderDialogCancel),
      );
      await tester.pumpAndSettle();
      expect(await captured.result, isNull);
    });

    testWidgets('Create pops with the trimmed name', (tester) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;
      await tester.enterText(find.byType(TextField), '  Books  ');
      await tester.pump();
      await tester.tap(find.text(l10n.createFolderDialogCreate));
      await tester.pumpAndSettle();
      expect(await captured.result, 'Books');
    });

    testWidgets('submitting via the keyboard pops with the trimmed name', (
      tester,
    ) async {
      final captured = await openDialog(tester);
      await tester.enterText(find.byType(TextField), '  Books  ');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(await captured.result, 'Books');
    });

    testWidgets(
      'submitting via the keyboard while Create is disabled is a no-op',
      (tester) async {
        final captured = await openDialog(tester);
        final l10n = captured.context.l10n;

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Dialog still open.
        expect(find.text(l10n.createFolderDialogTitle), findsOneWidget);

        await tester.tap(find.text(l10n.createFolderDialogCancel));
        await tester.pumpAndSettle();
        await captured.result;
      },
    );
  });
}
