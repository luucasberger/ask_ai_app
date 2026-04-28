import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/widgets/folder_tile.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  Folder buildFolder({String id = 'f0', String name = 'A folder'}) {
    return Folder(id: id, name: name, createdAt: DateTime.utc(2026, 4, 27));
  }

  Future<void> pumpTile(
    WidgetTester tester, {
    Folder? folder,
    List<Widget> children = const [],
    VoidCallback? onRenameSelected,
    VoidCallback? onDeleteSelected,
  }) {
    return tester.pumpApp(
      Scaffold(
        body: ListView(
          children: [
            FolderTile(
              folder: folder ?? buildFolder(),
              onRenameSelected: onRenameSelected ?? () {},
              onDeleteSelected: onDeleteSelected ?? () {},
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  group(FolderTile, () {
    testWidgets('renders the folder name', (tester) async {
      await pumpTile(tester, folder: buildFolder(name: 'Books'));
      expect(find.text('Books'), findsOneWidget);
    });

    testWidgets('expanding the tile reveals the nested children', (
      tester,
    ) async {
      await pumpTile(
        tester,
        folder: buildFolder(name: 'Books'),
        children: const [ListTile(title: Text('Nested child'))],
      );

      // Children are not visible when collapsed.
      expect(find.text('Nested child'), findsNothing);

      await tester.tap(find.text('Books'));
      await tester.pumpAndSettle();

      expect(find.text('Nested child'), findsOneWidget);
    });

    testWidgets(
      'long-press opens a menu with localized Rename and Delete entries',
      (tester) async {
        late final BuildContext capturedContext;
        await tester.pumpApp(
          Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return ListView(
                  children: [
                    FolderTile(
                      folder: buildFolder(),
                      onRenameSelected: () {},
                      onDeleteSelected: () {},
                      children: const [],
                    ),
                  ],
                );
              },
            ),
          ),
        );

        await tester.longPress(find.byType(FolderTile));
        await tester.pumpAndSettle();

        expect(
          find.text(capturedContext.l10n.folderMenuRename),
          findsOneWidget,
        );
        expect(
          find.text(capturedContext.l10n.folderMenuDelete),
          findsOneWidget,
        );
      },
    );

    testWidgets('fires onRenameSelected when the Rename entry is tapped', (
      tester,
    ) async {
      var renames = 0;
      late final BuildContext capturedContext;
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return ListView(
                children: [
                  FolderTile(
                    folder: buildFolder(),
                    onRenameSelected: () => renames++,
                    onDeleteSelected: () {},
                    children: const [],
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.longPress(find.byType(FolderTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(capturedContext.l10n.folderMenuRename));
      await tester.pumpAndSettle();

      expect(renames, 1);
    });

    testWidgets('fires onDeleteSelected when the Delete entry is tapped', (
      tester,
    ) async {
      var deletes = 0;
      late final BuildContext capturedContext;
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return ListView(
                children: [
                  FolderTile(
                    folder: buildFolder(),
                    onRenameSelected: () {},
                    onDeleteSelected: () => deletes++,
                    children: const [],
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.longPress(find.byType(FolderTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(capturedContext.l10n.folderMenuDelete));
      await tester.pumpAndSettle();

      expect(deletes, equals(1));
    });

    testWidgets('long-pressing again while the menu is open closes it', (
      tester,
    ) async {
      late final BuildContext capturedContext;
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return ListView(
                children: [
                  FolderTile(
                    folder: buildFolder(),
                    onRenameSelected: () {},
                    onDeleteSelected: () {},
                    children: const [],
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.longPress(find.byType(FolderTile));
      await tester.pumpAndSettle();
      expect(
        find.text(capturedContext.l10n.folderMenuRename),
        findsOneWidget,
      );

      await tester.longPress(find.byType(FolderTile));
      await tester.pumpAndSettle();
      expect(
        find.text(capturedContext.l10n.folderMenuRename),
        findsNothing,
      );
    });
  });
}
