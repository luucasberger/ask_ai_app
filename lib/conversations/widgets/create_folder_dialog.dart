import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';

/// {@template create_folder_dialog}
/// Dialog launched from the drawer's "+" action, or from the
/// "New folder…" entry inside a conversation row's "Move to folder…"
/// submenu.
///
/// The text field is autofocused. **Create** is enabled only when the
/// trimmed value is non-empty; **Cancel** dismisses without saving.
///
/// Pop result:
/// - the trimmed folder name when the user confirms,
/// - `null` when the user cancels (or the dialog is dismissed).
/// {@endtemplate}
class CreateFolderDialog extends StatefulWidget {
  /// {@macro create_folder_dialog}
  const CreateFolderDialog({super.key});

  /// Shows the dialog and resolves with the user's chosen name, or
  /// `null` if the user cancelled.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const CreateFolderDialog(),
    );
  }

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canCreate => _controller.text.trim().isNotEmpty;

  void _onCreatePressed() {
    if (!_canCreate) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  void _onCancelPressed() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.createFolderDialogTitle),
      content: TextField(
        key: const Key('createFolderDialog_textField'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: l10n.createFolderDialogHint),
        onSubmitted: (_) => _onCreatePressed(),
      ),
      actions: [
        TextButton(
          onPressed: _onCancelPressed,
          child: Text(l10n.createFolderDialogCancel),
        ),
        TextButton(
          onPressed: _canCreate ? _onCreatePressed : null,
          child: Text(l10n.createFolderDialogCreate),
        ),
      ],
    );
  }
}
