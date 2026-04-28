import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/widgets/conversation_tile.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  Conversation buildConversation({
    String id = 'c0',
    String title = 'A conversation',
    String? folderId,
  }) {
    return Conversation(
      id: id,
      title: title,
      folderId: folderId,
      createdAt: DateTime.utc(2026, 4, 27),
      updatedAt: DateTime.utc(2026, 4, 27),
    );
  }

  Folder buildFolder({
    String id = 'f0',
    String name = 'A folder',
  }) {
    return Folder(id: id, name: name, createdAt: DateTime.utc(2026, 4, 27));
  }

  Future<void> pumpTile(
    WidgetTester tester, {
    Conversation? conversation,
    List<Folder> folders = const [],
    bool selected = false,
    VoidCallback? onTap,
    VoidCallback? onRenameSelected,
    VoidCallback? onDeleteSelected,
    ValueChanged<String?>? onMoveSelected,
    VoidCallback? onMoveToNewFolderSelected,
  }) {
    return tester.pumpApp(
      Scaffold(
        body: ConversationTile(
          conversation: conversation ?? buildConversation(),
          folders: folders,
          selected: selected,
          onTap: onTap ?? () {},
          onRenameSelected: onRenameSelected ?? () {},
          onDeleteSelected: onDeleteSelected ?? () {},
          onMoveSelected: onMoveSelected ?? (_) {},
          onMoveToNewFolderSelected: onMoveToNewFolderSelected ?? () {},
        ),
      ),
    );
  }

  Future<BuildContext> pumpTileWithCapturedContext(
    WidgetTester tester, {
    Conversation? conversation,
    List<Folder> folders = const [],
    VoidCallback? onRenameSelected,
    VoidCallback? onDeleteSelected,
    ValueChanged<String?>? onMoveSelected,
    VoidCallback? onMoveToNewFolderSelected,
  }) async {
    late BuildContext capturedContext;
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) {
            capturedContext = context;
            return ConversationTile(
              conversation: conversation ?? buildConversation(),
              folders: folders,
              selected: false,
              onTap: () {},
              onRenameSelected: onRenameSelected ?? () {},
              onDeleteSelected: onDeleteSelected ?? () {},
              onMoveSelected: onMoveSelected ?? (_) {},
              onMoveToNewFolderSelected: onMoveToNewFolderSelected ?? () {},
            );
          },
        ),
      ),
    );
    return capturedContext;
  }

  group(ConversationTile, () {
    testWidgets('renders the conversation title', (tester) async {
      await pumpTile(
        tester,
        conversation: buildConversation(title: 'Lunch plans'),
      );
      expect(find.text('Lunch plans'), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var taps = 0;
      await pumpTile(tester, onTap: () => taps++);

      await tester.tap(find.byType(ConversationTile));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('marks the underlying $ListTile as selected', (tester) async {
      await pumpTile(tester, selected: true);

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.selected, isTrue);
    });

    testWidgets(
      'long-press opens a menu with localized Rename, Move, and Delete entries',
      (tester) async {
        final context = await pumpTileWithCapturedContext(tester);

        await tester.longPress(find.byType(ConversationTile));
        await tester.pumpAndSettle();

        expect(find.text(context.l10n.conversationMenuRename), findsOneWidget);
        expect(
          find.text(context.l10n.conversationMenuMoveToFolder),
          findsOneWidget,
        );
        expect(find.text(context.l10n.conversationMenuDelete), findsOneWidget);
      },
    );

    testWidgets('fires onRenameSelected when the Rename entry is tapped', (
      tester,
    ) async {
      var renames = 0;
      final context = await pumpTileWithCapturedContext(
        tester,
        onRenameSelected: () => renames++,
      );

      await tester.longPress(find.byType(ConversationTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(context.l10n.conversationMenuRename));
      await tester.pumpAndSettle();

      expect(renames, 1);
    });

    testWidgets('fires onDeleteSelected when the Delete entry is tapped', (
      tester,
    ) async {
      var deletes = 0;
      final context = await pumpTileWithCapturedContext(
        tester,
        onDeleteSelected: () => deletes++,
      );

      await tester.longPress(find.byType(ConversationTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(context.l10n.conversationMenuDelete));
      await tester.pumpAndSettle();

      expect(deletes, 1);
    });

    testWidgets('long-pressing again while the menu is open closes it', (
      tester,
    ) async {
      final context = await pumpTileWithCapturedContext(tester);

      await tester.longPress(find.byType(ConversationTile));
      await tester.pumpAndSettle();
      expect(find.text(context.l10n.conversationMenuRename), findsOneWidget);

      await tester.longPress(find.byType(ConversationTile));
      await tester.pumpAndSettle();
      expect(find.text(context.l10n.conversationMenuRename), findsNothing);
    });

    group('Move to folder submenu', () {
      testWidgets(
        'lists every folder, "Uncategorized", and "New folder…"',
        (tester) async {
          final context = await pumpTileWithCapturedContext(
            tester,
            folders: [
              buildFolder(id: 'f1', name: 'Books'),
              buildFolder(id: 'f2', name: 'Lifestyle'),
            ],
          );

          await tester.longPress(find.byType(ConversationTile));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToFolder),
          );
          await tester.pumpAndSettle();

          expect(find.text('Books'), findsOneWidget);
          expect(find.text('Lifestyle'), findsOneWidget);
          expect(
            find.text(context.l10n.conversationMenuMoveToUncategorized),
            findsOneWidget,
          );
          expect(
            find.text(context.l10n.conversationMenuMoveToNewFolder),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'fires onMoveSelected with the folder id when a folder is tapped',
        (tester) async {
          String? moved = 'unset';
          final context = await pumpTileWithCapturedContext(
            tester,
            folders: [buildFolder(id: 'f1', name: 'Books')],
            onMoveSelected: (id) => moved = id,
          );

          await tester.longPress(find.byType(ConversationTile));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToFolder),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Books'));
          await tester.pumpAndSettle();

          expect(moved, equals('f1'));
        },
      );

      testWidgets(
        'fires onMoveSelected with null when "Uncategorized" is tapped',
        (tester) async {
          String? moved = 'unset';
          final context = await pumpTileWithCapturedContext(
            tester,
            onMoveSelected: (id) => moved = id,
          );

          await tester.longPress(find.byType(ConversationTile));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToFolder),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToUncategorized),
          );
          await tester.pumpAndSettle();

          expect(moved, isNull);
        },
      );

      testWidgets(
        'fires onMoveToNewFolderSelected when "New folder…" is tapped',
        (tester) async {
          var calls = 0;
          final context = await pumpTileWithCapturedContext(
            tester,
            onMoveToNewFolderSelected: () => calls++,
          );

          await tester.longPress(find.byType(ConversationTile));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToFolder),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToNewFolder),
          );
          await tester.pumpAndSettle();

          expect(calls, equals(1));
        },
      );
    });
  });
}
