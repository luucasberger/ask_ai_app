import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';

/// {@template delete_folder_dialog}
/// Confirmation dialog launched from a folder row's long-press context
/// menu when the user picks **Delete**.
///
/// The body text names the conversation count via the
/// `deleteFolderDialogBody` plural string. Folder deletion **cascades**
/// to every conversation inside the folder and every message inside
/// those conversations — the count surfaced here is what tips the user
/// off before they confirm.
///
/// Pop result:
/// - `true` when the user confirms the delete,
/// - `false` (or `null`) when the user cancels.
/// {@endtemplate}
class DeleteFolderDialog extends StatelessWidget {
  /// {@macro delete_folder_dialog}
  const DeleteFolderDialog({
    required this.folder,
    required this.conversationCount,
    super.key,
  });

  /// Shows the dialog and resolves with `true` when the user confirms
  /// the delete, or `false` otherwise.
  static Future<bool> show(
    BuildContext context, {
    required Folder folder,
    required int conversationCount,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteFolderDialog(
        folder: folder,
        conversationCount: conversationCount,
      ),
    );
    return result ?? false;
  }

  /// The folder being deleted; its name appears in the title.
  final Folder folder;

  /// Number of conversations that will be cascade-deleted alongside
  /// the folder. Drives the body copy.
  final int conversationCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.deleteFolderDialogTitle(folder.name)),
      content: Text(l10n.deleteFolderDialogBody(conversationCount)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.deleteFolderDialogCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteFolderDialogConfirm),
        ),
      ],
    );
  }
}
