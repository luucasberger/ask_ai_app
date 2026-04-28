import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';

/// {@template chat_composer}
/// The bottom-of-screen input row: a [TextField] for the next message
/// paired with a send button that swaps to a circular progress
/// indicator while a response is in flight (including the typewriter
/// reveal).
///
/// The composer is intentionally bloc-agnostic — the parent passes
/// [onSubmit] and the [inFlight] gate, and decides whether the
/// submission goes through `ChatBloc` (active conversation) or
/// `AppBloc` (empty-state first send).
/// {@endtemplate}
class ChatComposer extends StatefulWidget {
  /// {@macro chat_composer}
  const ChatComposer({
    required this.onSubmit,
    required this.inFlight,
    super.key,
  });

  /// Invoked with the raw (untrimmed) text from the field when the
  /// user taps send (or hits the keyboard send action). Only fires
  /// when the trimmed text is non-empty and [inFlight] is `false`.
  final ValueChanged<String> onSubmit;

  /// `true` while a response is in flight — the send button renders
  /// as a spinner and submissions are blocked.
  final bool inFlight;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (widget.inFlight) return;
    final text = controller.text;
    if (text.trim().isEmpty) return;
    widget.onSubmit(text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.xs,
        spacing.md,
        spacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(hintText: l10n.chatComposerHint),
            ),
          ),
          SizedBox(width: spacing.xs),
          _SendButton(
            inFlight: widget.inFlight,
            onPressed: widget.inFlight ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.inFlight, required this.onPressed});

  final bool inFlight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (inFlight) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Semantics(
          label: l10n.chatComposerSendingLabel,
          child: const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    return IconButton.filled(
      tooltip: l10n.chatComposerSendLabel,
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_upward_rounded),
    );
  }
}
