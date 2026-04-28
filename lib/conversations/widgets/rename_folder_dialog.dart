import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';

/// {@template rename_folder_dialog}
/// Dialog launched from a folder row's long-press context menu when
/// the user picks **Rename**.
///
/// The text field is autofocused and prefilled with the folder's
/// current name. **Save** is enabled only when the trimmed value is
/// non-empty and differs from the current name; **Cancel** dismisses
/// without saving.
///
/// Pop result:
/// - the trimmed new name when the user confirms,
/// - `null` when the user cancels (or the dialog is dismissed).
/// {@endtemplate}
class RenameFolderDialog extends StatefulWidget {
  /// {@macro rename_folder_dialog}
  const RenameFolderDialog({required this.folder, super.key});

  /// Shows the dialog and resolves with the user's chosen name, or
  /// `null` if the user cancelled.
  static Future<String?> show(BuildContext context, Folder folder) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameFolderDialog(folder: folder),
    );
  }

  /// The folder being renamed; its current name seeds the text field.
  final Folder folder;

  @override
  State<RenameFolderDialog> createState() => _RenameFolderDialogState();
}

class _RenameFolderDialogState extends State<RenameFolderDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.folder.name)
      ..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSave {
    final trimmed = _controller.text.trim();
    return trimmed.isNotEmpty && trimmed != widget.folder.name;
  }

  void _onSavePressed() {
    if (!_canSave) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  void _onCancelPressed() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.renameFolderDialogTitle),
      content: TextField(
        key: const Key('renameFolderDialog_textField'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: l10n.renameFolderDialogHint),
        onSubmitted: (_) => _onSavePressed(),
      ),
      actions: [
        TextButton(
          onPressed: _onCancelPressed,
          child: Text(l10n.renameFolderDialogCancel),
        ),
        TextButton(
          onPressed: _canSave ? _onSavePressed : null,
          child: Text(l10n.renameFolderDialogSave),
        ),
      ],
    );
  }
}
