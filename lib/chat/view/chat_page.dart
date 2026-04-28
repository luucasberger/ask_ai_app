import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/app/bloc/app_bloc.dart';
import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:ask_ai_app/chat/widgets/widgets.dart';
import 'package:ask_ai_app/conversations/conversations.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Provides the page-scoped [ConversationsCubit] used by both the
/// drawer and the AppBar title, then renders [ChatView].
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConversationsCubit(
        conversationsRepository: context.read<ConversationsRepository>(),
      ),
      child: const ChatView(),
    );
  }
}

/// {@template chat_view}
/// The chat surface. Hosts the conversations drawer, the AppBar
/// (whose title binds to the active conversation), and either the
/// active chat surface or the empty-state composer depending on
/// [AppState.activeConversationId].
/// {@endtemplate}
class ChatView extends StatelessWidget {
  /// {@macro chat_view}
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      listenWhen: (oldState, newState) =>
          newState.transientError != null &&
          newState.transientError != oldState.transientError,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_appErrorMessage(context, state.transientError!)),
            ),
          );
        context.read<AppBloc>().add(const AppTransientErrorCleared());
      },
      child: BlocBuilder<AppBloc, AppState>(
        buildWhen: (oldState, newState) =>
            oldState.activeConversationId != newState.activeConversationId,
        builder: (context, appState) {
          final activeId = appState.activeConversationId;
          return Scaffold(
            appBar: AppBar(
              title: _AppBarTitle(activeConversationId: activeId),
            ),
            drawer: Builder(
              builder: (context) => ConversationsDrawerView(
                activeConversationId: activeId,
                onConversationTapped: (id) {
                  Scaffold.of(context).closeDrawer();
                  context.read<AppBloc>().add(AppConversationActivated(id));
                },
                onNewChatTapped: () {
                  Scaffold.of(context).closeDrawer();
                  context
                      .read<AppBloc>()
                      .add(const AppNewConversationRequested());
                },
              ),
            ),
            body: SafeArea(
              top: false,
              child: activeId == null
                  ? const _NewChatBody()
                  : _ActiveChatBody(
                      key: ValueKey(activeId),
                      conversationId: activeId,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.activeConversationId});

  final String? activeConversationId;

  @override
  Widget build(BuildContext context) {
    final fallback = context.l10n.chatAppBarTitle;
    if (activeConversationId == null) return Text(fallback);
    return BlocBuilder<ConversationsCubit, ConversationsState>(
      builder: (context, state) {
        final match = state.conversations
            .where((c) => c.id == activeConversationId)
            .firstOrNull;
        return Text(
          match?.title ?? fallback,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _NewChatBody extends StatelessWidget {
  const _NewChatBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: _ChatEmptyState()),
        ChatComposer(
          inFlight: false,
          onSubmit: (text) =>
              context.read<AppBloc>().add(AppFirstMessageSubmitted(text)),
        ),
      ],
    );
  }
}

class _ActiveChatBody extends StatelessWidget {
  const _ActiveChatBody({required this.conversationId, super.key});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        conversationId: conversationId,
        conversationsRepository: context.read(),
        chatRepositoryRegistry: context.read(),
      ),
      child: BlocListener<ChatBloc, ChatState>(
        listenWhen: (oldState, newState) =>
            newState.transientError != null &&
            newState.transientError != oldState.transientError,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  _chatErrorMessage(context, state.transientError!),
                ),
              ),
            );
          context.read<ChatBloc>().add(const ChatTransientErrorCleared());
        },
        child: const Column(
          children: [
            Expanded(child: _ChatMessagesList()),
            _ActiveChatComposer(),
          ],
        ),
      ),
    );
  }
}

class _ActiveChatComposer extends StatelessWidget {
  const _ActiveChatComposer();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (oldState, newState) =>
          oldState.streamingMessageId != newState.streamingMessageId,
      builder: (context, appState) {
        return BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (oldState, newState) =>
              oldState.awaitingResponse != newState.awaitingResponse,
          builder: (context, chatState) {
            final inFlight = chatState.awaitingResponse ||
                appState.streamingMessageId != null;
            return ChatComposer(
              inFlight: inFlight,
              onSubmit: (text) =>
                  context.read<ChatBloc>().add(ChatMessageSubmitted(text)),
            );
          },
        );
      },
    );
  }
}

class _ChatMessagesList extends StatelessWidget {
  const _ChatMessagesList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (oldState, newState) => oldState.messages != newState.messages,
      builder: (context, state) {
        if (state.messages.isEmpty) return const _ChatEmptyState();

        final spacing = context.appSpacing;
        final reversed = state.messages.reversed.toList(growable: false);
        return BlocSelector<AppBloc, AppState, String?>(
          selector: (state) => state.streamingMessageId,
          builder: (context, streamingId) {
            return ListView.separated(
              reverse: true,
              padding: EdgeInsets.symmetric(
                horizontal: spacing.md,
                vertical: spacing.sm,
              ),
              itemCount: reversed.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: spacing.xs),
              itemBuilder: (context, index) {
                final message = reversed[index];
                final streaming = message.id == streamingId;
                return ChatBubble(
                  key: ValueKey('chat-bubble-${message.id}'),
                  message: message,
                  streaming: streaming,
                  onStreamingCompleted: () => context
                      .read<AppBloc>()
                      .add(AppStreamingCompleted(message.id)),
                );
              },
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

String _chatErrorMessage(BuildContext context, ChatTransientError error) {
  final l10n = context.l10n;
  return switch (error) {
    ChatTransientError.persistenceFailed => l10n.chatErrorPersistenceFailed,
    ChatTransientError.connectionFailed => l10n.chatErrorConnectionFailed,
    ChatTransientError.sendFailed => l10n.chatErrorSendFailed,
    ChatTransientError.messageTooLarge => l10n.chatErrorMessageTooLarge,
  };
}

String _appErrorMessage(BuildContext context, AppTransientError error) {
  final l10n = context.l10n;
  return switch (error) {
    AppTransientError.persistenceFailed => l10n.chatErrorPersistenceFailed,
    AppTransientError.connectionFailed => l10n.chatErrorConnectionFailed,
    AppTransientError.sendFailed => l10n.chatErrorSendFailed,
    AppTransientError.messageTooLarge => l10n.chatErrorMessageTooLarge,
  };
}
