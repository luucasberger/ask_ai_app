import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/widgets/delete_folder_dialog.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  Folder buildFolder({String id = 'f0', String name = 'Books'}) {
    return Folder(id: id, name: name, createdAt: DateTime.utc(2026, 4, 27));
  }

  Future<({Future<bool> result, BuildContext context})> openDialog(
    WidgetTester tester, {
    Folder? folder,
    int conversationCount = 0,
  }) async {
    final completer = Completer<({Future<bool> result, BuildContext ctx})>();
    await tester.pumpApp(
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              final result = DeleteFolderDialog.show(
                context,
                folder: folder ?? buildFolder(),
                conversationCount: conversationCount,
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

  group(DeleteFolderDialog, () {
    testWidgets(
      'renders localized title (with folder name) and actions',
      (tester) async {
        final captured = await openDialog(
          tester,
          folder: buildFolder(),
        );
        final l10n = captured.context.l10n;

        expect(
          find.text(l10n.deleteFolderDialogTitle('Books')),
          findsOneWidget,
        );
        expect(find.text(l10n.deleteFolderDialogCancel), findsOneWidget);
        expect(find.text(l10n.deleteFolderDialogConfirm), findsOneWidget);

        await tester.tap(find.text(l10n.deleteFolderDialogCancel));
        await tester.pumpAndSettle();
        await captured.result;
      },
    );

    testWidgets('renders the empty body for a folder with no conversations', (
      tester,
    ) async {
      final captured = await openDialog(tester);
      final l10n = captured.context.l10n;
      expect(find.text(l10n.deleteFolderDialogBody(0)), findsOneWidget);

      await tester.tap(find.text(l10n.deleteFolderDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('renders the singular body for a folder with one conversation',
        (tester) async {
      final captured = await openDialog(tester, conversationCount: 1);
      final l10n = captured.context.l10n;
      expect(find.text(l10n.deleteFolderDialogBody(1)), findsOneWidget);

      await tester.tap(find.text(l10n.deleteFolderDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('renders the plural body and includes the count', (
      tester,
    ) async {
      final captured = await openDialog(tester, conversationCount: 12);
      final l10n = captured.context.l10n;
      expect(find.text(l10n.deleteFolderDialogBody(12)), findsOneWidget);
      expect(
        find.textContaining('12'),
        findsWidgets,
        reason: 'plural body should embed the count',
      );

      await tester.tap(find.text(l10n.deleteFolderDialogCancel));
      await tester.pumpAndSettle();
      await captured.result;
    });

    testWidgets('Cancel resolves to false', (tester) async {
      final captured = await openDialog(tester);
      await tester.tap(
        find.text(captured.context.l10n.deleteFolderDialogCancel),
      );
      await tester.pumpAndSettle();
      expect(await captured.result, isFalse);
    });

    testWidgets('Delete resolves to true', (tester) async {
      final captured = await openDialog(tester);
      await tester.tap(
        find.text(captured.context.l10n.deleteFolderDialogConfirm),
      );
      await tester.pumpAndSettle();
      expect(await captured.result, isTrue);
    });

    testWidgets('barrier dismiss resolves to false', (tester) async {
      final captured = await openDialog(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(await captured.result, isFalse);
    });
  });
}
