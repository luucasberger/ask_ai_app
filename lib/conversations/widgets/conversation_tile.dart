import 'package:app_ui/app_ui.dart';
import 'package:conversations_repository/conversations_repository.dart';

/// {@template conversation_tile}
/// A single row inside the conversations drawer.
///
/// Tapping fires [onTap]; the long-press gesture is intentionally not
/// wired here — bonus #2 will attach the rename / move / delete
/// context menu via this same row.
/// {@endtemplate}
class ConversationTile extends StatelessWidget {
  /// {@macro conversation_tile}
  const ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// The conversation rendered in the row.
  final Conversation conversation;

  /// Whether this conversation is the currently active one. Drives
  /// the selected styling on the underlying [ListTile].
  final bool selected;

  /// Invoked when the user taps the row.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: selected,
      onTap: onTap,
    );
  }
}
