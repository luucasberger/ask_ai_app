import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';

/// {@template delete_conversation_dialog}
/// Confirmation dialog launched from a conversation row's long-press
/// context menu when the user picks **Delete**.
///
/// The dialog body is a generic confirmation (no count line — that
/// copy is reserved for the folder-delete dialog in bonus #3).
///
/// Pop result:
/// - `true` when the user confirms the delete,
/// - `false` (or `null`) when the user cancels.
/// {@endtemplate}
class DeleteConversationDialog extends StatelessWidget {
  /// {@macro delete_conversation_dialog}
  const DeleteConversationDialog({super.key});

  /// Shows the dialog and resolves with `true` when the user confirms
  /// the delete, or `false` otherwise.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteConversationDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.deleteConversationDialogTitle),
      content: Text(l10n.deleteConversationDialogBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.deleteConversationDialogCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteConversationDialogConfirm),
        ),
      ],
    );
  }
}
