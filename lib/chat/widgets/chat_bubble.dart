import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/chat/model/message.dart';
import 'package:ask_ai_app/chat/widgets/typewriter_text.dart';

/// {@template chat_bubble}
/// Visual container for a single [Message].
///
/// User messages align to the right with the primary [AppColors.userBubble]
/// background; assistant messages align to the left with
/// [AppColors.assistantBubble]. When [streaming] is true the bubble plays
/// the [TypewriterText] reveal and fires [onStreamingCompleted] once the
/// reveal finishes.
/// {@endtemplate}
class ChatBubble extends StatelessWidget {
  /// {@macro chat_bubble}
  const ChatBubble({
    required this.message,
    required this.streaming,
    required this.onStreamingCompleted,
    super.key,
  });

  /// The message rendered inside the bubble.
  final Message message;

  /// Whether the bubble's text should reveal character-by-character.
  final bool streaming;

  /// Called when the typewriter reveal finishes.
  ///
  /// Only invoked when [streaming] is true.
  final VoidCallback onStreamingCompleted;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final appRadii = context.appRadii;
    final appSpacing = context.appSpacing;
    final isUser = message.role == MessageRole.user;
    final textStyle = context.textTheme.bodyMedium?.copyWith(
      color: isUser ? appColors.onUserBubble : appColors.onAssistantBubble,
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: appSpacing.md,
            vertical: appSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isUser ? appColors.userBubble : appColors.assistantBubble,
            borderRadius: BorderRadius.circular(appRadii.lg),
          ),
          child: streaming
              ? TypewriterText(
                  key: ValueKey('typewriter-${message.id}'),
                  text: message.text,
                  style: textStyle,
                  onCompleted: onStreamingCompleted,
                )
              : Text(message.text, style: textStyle),
        ),
      ),
    );
  }
}
