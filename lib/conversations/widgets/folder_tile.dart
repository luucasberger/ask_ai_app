import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';

/// {@template folder_tile}
/// A folder row inside the conversations drawer.
///
/// Wraps an [ExpansionTile] so the folder collapses/expands its
/// nested conversation rows on tap. Long-pressing the row opens a
/// [MenuAnchor]-anchored floating context menu with **Rename** and
/// **Delete** entries; the corresponding callbacks fire when the user
/// picks an item.
/// {@endtemplate}
class FolderTile extends StatelessWidget {
  /// {@macro folder_tile}
  const FolderTile({
    required this.folder,
    required this.children,
    required this.onRenameSelected,
    required this.onDeleteSelected,
    super.key,
  });

  /// The folder rendered in the row.
  final Folder folder;

  /// Conversation rows nested inside this folder's expansion area.
  final List<Widget> children;

  /// Invoked when the user picks **Rename** from the context menu.
  final VoidCallback onRenameSelected;

  /// Invoked when the user picks **Delete** from the context menu.
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: onRenameSelected,
          child: Text(l10n.folderMenuRename),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: onDeleteSelected,
          child: Text(l10n.folderMenuDelete),
        ),
      ],
      builder: (context, controller, _) {
        return GestureDetector(
          onLongPress: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: ExpansionTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: children,
          ),
        );
      },
    );
  }
}
