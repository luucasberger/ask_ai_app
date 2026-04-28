import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';

/// {@template conversation_tile}
/// A single row inside the conversations drawer.
///
/// Tapping fires [onTap]. Long-pressing opens a [MenuAnchor]-anchored
/// floating context menu with **Rename**, **Move to folder…** (a
/// cascading submenu listing every folder, "Uncategorized", and a
/// "New folder…" entry), and **Delete** entries; the corresponding
/// callbacks fire when the user picks an item.
/// {@endtemplate}
class ConversationTile extends StatelessWidget {
  /// {@macro conversation_tile}
  const ConversationTile({
    required this.conversation,
    required this.folders,
    required this.selected,
    required this.onTap,
    required this.onRenameSelected,
    required this.onDeleteSelected,
    required this.onMoveSelected,
    required this.onMoveToNewFolderSelected,
    super.key,
  });

  /// The conversation rendered in the row.
  final Conversation conversation;

  /// Every existing folder. Drives the entries inside the
  /// **Move to folder…** submenu.
  final List<Folder> folders;

  /// Whether this conversation is the currently active one. Drives
  /// the selected styling on the underlying [ListTile].
  final bool selected;

  /// Invoked when the user taps the row.
  final VoidCallback onTap;

  /// Invoked when the user picks **Rename** from the context menu.
  final VoidCallback onRenameSelected;

  /// Invoked when the user picks **Delete** from the context menu.
  final VoidCallback onDeleteSelected;

  /// Invoked when the user picks a destination from the **Move to
  /// folder…** submenu. The argument is the target folder id, or
  /// `null` for "Uncategorized".
  final ValueChanged<String?> onMoveSelected;

  /// Invoked when the user picks **New folder…** from the move
  /// submenu. The caller is responsible for prompting for a name and
  /// then performing the create-and-move.
  final VoidCallback onMoveToNewFolderSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: onRenameSelected,
          child: Text(l10n.conversationMenuRename),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.drive_file_move_outlined),
          menuChildren: [
            for (final folder in folders)
              MenuItemButton(
                onPressed: () => onMoveSelected(folder.id),
                child: Text(folder.name),
              ),
            MenuItemButton(
              onPressed: () => onMoveSelected(null),
              child: Text(l10n.conversationMenuMoveToUncategorized),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.create_new_folder_outlined),
              onPressed: onMoveToNewFolderSelected,
              child: Text(l10n.conversationMenuMoveToNewFolder),
            ),
          ],
          child: Text(l10n.conversationMenuMoveToFolder),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: onDeleteSelected,
          child: Text(l10n.conversationMenuDelete),
        ),
      ],
      builder: (context, controller, _) {
        return ListTile(
          title: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          selected: selected,
          onTap: onTap,
          onLongPress: () =>
              controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}
