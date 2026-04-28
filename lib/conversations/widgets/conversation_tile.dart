import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';

/// {@template conversation_tile}
/// A single row inside the conversations drawer.
///
/// Tapping fires [onTap]. Long-pressing opens a [MenuAnchor]-anchored
/// floating context menu with **Rename** and **Delete** entries; the
/// corresponding [onRenameSelected] / [onDeleteSelected] callbacks
/// fire when the user picks an item. (The "Move to folder…" entry
/// ships with bonus #3.)
/// {@endtemplate}
class ConversationTile extends StatelessWidget {
  /// {@macro conversation_tile}
  const ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onRenameSelected,
    required this.onDeleteSelected,
    super.key,
  });

  /// The conversation rendered in the row.
  final Conversation conversation;

  /// Whether this conversation is the currently active one. Drives
  /// the selected styling on the underlying [ListTile].
  final bool selected;

  /// Invoked when the user taps the row.
  final VoidCallback onTap;

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
          child: Text(l10n.conversationMenuRename),
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
