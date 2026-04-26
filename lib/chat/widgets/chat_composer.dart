import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// {@template chat_composer}
/// The bottom-of-screen input row: a [TextField] for the user's next
/// message paired with a send button that swaps to a circular progress
/// indicator while a response is in flight (including the typewriter
/// reveal).
/// {@endtemplate}
class ChatComposer extends StatefulWidget {
  /// {@macro chat_composer}
  const ChatComposer({super.key});

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
    final text = controller.text;
    if (text.trim().isEmpty) return;
    final bloc = context.read<ChatBloc>();
    if (!bloc.state.canSend) return;
    bloc.add(ChatMessageSubmitted(text));
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (oldState, newState) {
        if (oldState.canSend != newState.canSend) {
          return true;
        }

        if (oldState.isResponseInFlight != newState.isResponseInFlight) {
          return true;
        }

        if (oldState.status != newState.status) {
          return true;
        }

        return false;
      },
      builder: (context, state) {
        final isReady = state.status == ChatStatus.ready;
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
                  enabled: isReady,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(hintText: l10n.chatComposerHint),
                ),
              ),
              SizedBox(width: spacing.xs),
              _SendButton(
                inFlight: state.isResponseInFlight,
                onPressed: state.canSend ? _sendMessage : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.inFlight,
    required this.onPressed,
  });

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
