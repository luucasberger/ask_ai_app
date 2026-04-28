import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';

/// {@template rename_conversation_dialog}
/// Confirmation dialog launched from a conversation row's long-press
/// context menu.
///
/// The text field is autofocused and prefilled with the conversation's
/// current title. **Save** is enabled only when the trimmed value is
/// non-empty and differs from the current title; **Cancel** dismisses
/// without saving.
///
/// Pop result:
/// - the trimmed new title when the user confirms,
/// - `null` when the user cancels (or the dialog is dismissed).
/// {@endtemplate}
class RenameConversationDialog extends StatefulWidget {
  /// {@macro rename_conversation_dialog}
  const RenameConversationDialog({required this.conversation, super.key});

  /// Shows the dialog and resolves with the user's chosen title, or
  /// `null` if the user cancelled.
  static Future<String?> show(
    BuildContext context,
    Conversation conversation,
  ) {
    return showDialog<String>(
      context: context,
      builder: (_) => RenameConversationDialog(conversation: conversation),
    );
  }

  /// The conversation being renamed; its current title seeds the
  /// text field.
  final Conversation conversation;

  @override
  State<RenameConversationDialog> createState() =>
      _RenameConversationDialogState();
}

class _RenameConversationDialogState extends State<RenameConversationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.conversation.title)
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
    return trimmed.isNotEmpty && trimmed != widget.conversation.title;
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
      title: Text(l10n.renameConversationDialogTitle),
      content: TextField(
        key: const Key('renameConversationDialog_textField'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: l10n.renameConversationDialogHint,
        ),
        onSubmitted: (_) => _onSavePressed(),
      ),
      actions: [
        TextButton(
          onPressed: _onCancelPressed,
          child: Text(l10n.renameConversationDialogCancel),
        ),
        TextButton(
          onPressed: _canSave ? _onSavePressed : null,
          child: Text(l10n.renameConversationDialogSave),
        ),
      ],
    );
  }
}
