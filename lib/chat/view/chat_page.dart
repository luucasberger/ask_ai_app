import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:ask_ai_app/chat/widgets/widgets.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Provides a [ChatBloc] for the chat surface and renders the [ChatView].
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        chatRepository: context.read<ChatRepository>(),
      )..add(const ChatStarted()),
      child: const ChatView(),
    );
  }
}

/// The active conversation surface: an [AppBar], the scrollable list of
/// exchanged messages, and the [ChatComposer] anchored at the bottom.
class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatAppBarTitle)),
      body: BlocListener<ChatBloc, ChatState>(
        listenWhen: (oldState, newState) =>
            newState.transientError != null &&
            newState.transientError != oldState.transientError,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                switch (state.transientError!) {
                  ChatTransientError.connectionFailed =>
                    l10n.chatErrorConnectionFailed,
                  ChatTransientError.sendFailed => l10n.chatErrorSendFailed,
                  ChatTransientError.messageTooLarge =>
                    l10n.chatErrorMessageTooLarge,
                },
              ),
            ),
          ),
        child: const SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(child: _ChatMessagesList()),
              ChatComposer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessagesList extends StatelessWidget {
  const _ChatMessagesList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (oldState, newState) =>
          oldState.messages != newState.messages ||
          oldState.streamingMessageId != newState.streamingMessageId,
      builder: (context, state) {
        if (state.messages.isEmpty) return const _ChatEmptyState();

        final spacing = context.appSpacing;
        final reversed = state.messages.reversed.toList(growable: false);
        return ListView.separated(
          reverse: true,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          itemCount: reversed.length,
          separatorBuilder: (context, index) => SizedBox(height: spacing.xs),
          itemBuilder: (context, index) {
            final message = reversed[index];
            final streaming = message.id == state.streamingMessageId;
            return ChatBubble(
              key: ValueKey('chat-bubble-${message.id}'),
              message: message,
              streaming: streaming,
              onStreamingCompleted: () => context.read<ChatBloc>().add(
                    ChatStreamingCompleted(message.id),
                  ),
            );
          },
        );
      },
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSpacing = context.appSpacing;
    final appColors = context.appColors;
    final textTheme = context.textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: appSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.chatEmptyTitle,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: appSpacing.xs),
            Text(
              l10n.chatEmptyMessage,
              style: textTheme.bodyMedium?.copyWith(
                color: appColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
