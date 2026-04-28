import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/widgets/rename_folder_dialog.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  Folder buildFolder({String id = 'f0', String name = 'Original'}) {
    return Folder(id: id, name: name, createdAt: DateTime.utc(2026, 4, 27));
  }

  Future<({Future<String?> result, BuildContext context})> openDialog(
    WidgetTester tester, {
    Folder? folder,
  }) async {
    final completer = Completer<({Future<String?> result, BuildContext ctx})>();
    await tester.pumpApp(
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              final result = RenameFolderDialog.show(
                context,
                folder ?? buildFolder(),
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

  group(RenameFolderDialog, () {
    testWidgets('renders localized title, hint, and actions', (tester) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;
      expect(find.text(l10n.renameFolderDialogTitle), findsOneWidget);
      expect(find.text(l10n.renameFolderDialogHint), findsOneWidget);
      expect(find.text(l10n.renameFolderDialogCancel), findsOneWidget);
      expect(find.text(l10n.renameFolderDialogSave), findsOneWidget);

      await tester.tap(find.text(l10n.renameFolderDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('prefills the text field with the current name', (
      tester,
    ) async {
      final captured = await openDialog(
        tester,
        folder: buildFolder(name: 'Reading'),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Reading');

      await tester.tap(
        find.text(captured.context.l10n.renameFolderDialogCancel),
      );
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Save is disabled when the field is unchanged', (tester) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;

      final save = tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10n.renameFolderDialogSave),
      );
      expect(save.onPressed, isNull);

      await tester.tap(find.text(l10n.renameFolderDialogCancel));
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

      final save = tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10n.renameFolderDialogSave),
      );
      expect(save.onPressed, isNull);

      await tester.tap(find.text(l10n.renameFolderDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Cancel pops with null', (tester) async {
      final captured = await openDialog(tester);
      await tester.tap(
        find.text(captured.context.l10n.renameFolderDialogCancel),
      );
      await tester.pumpAndSettle();
      expect(await captured.result, isNull);
    });

    testWidgets('Save pops with the trimmed new name', (tester) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;
      await tester.enterText(find.byType(TextField), '  Updated  ');
      await tester.pump();
      await tester.tap(find.text(l10n.renameFolderDialogSave));
      await tester.pumpAndSettle();
      expect(await captured.result, 'Updated');
    });

    testWidgets('submitting via the keyboard pops with the trimmed name', (
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

        expect(find.text(l10n.renameFolderDialogTitle), findsOneWidget);

        await tester.tap(find.text(l10n.renameFolderDialogCancel));
        await tester.pumpAndSettle();
        await captured.result;
      },
    );
  });
}
