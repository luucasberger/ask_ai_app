import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/cubit/conversations_cubit.dart';
import 'package:ask_ai_app/conversations/widgets/widgets.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Provides a [ConversationsCubit] for the drawer surface and renders
/// the [ConversationsDrawerView].
class ConversationsDrawer extends StatelessWidget {
  /// {@macro conversations_drawer_view}
  const ConversationsDrawer({
    required this.activeConversationId,
    required this.onConversationTapped,
    required this.onNewChatTapped,
    super.key,
  });

  /// {@template conversations_drawer.activeConversationId}
  /// The id of the currently active conversation, or `null` for a
  /// new (not-yet-persisted) chat.
  /// {@endtemplate}
  final String? activeConversationId;

  /// {@template conversations_drawer.onConversationTapped}
  /// Invoked with the conversation id when the user taps a tile.
  /// {@endtemplate}
  final ValueChanged<String> onConversationTapped;

  /// {@template conversations_drawer.onNewChatTapped}
  /// Invoked when the user taps the drawer header's "New chat" CTA.
  /// {@endtemplate}
  final VoidCallback onNewChatTapped;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConversationsCubit(
        conversationsRepository: context.read(),
      ),
      child: ConversationsDrawerView(
        activeConversationId: activeConversationId,
        onConversationTapped: onConversationTapped,
        onNewChatTapped: onNewChatTapped,
      ),
    );
  }
}

/// {@template conversations_drawer_view}
/// The drawer surface that lists every persisted conversation and
/// hosts the "New chat" CTA in its header.
/// {@endtemplate}
class ConversationsDrawerView extends StatelessWidget {
  /// {@macro conversations_drawer_view}
  const ConversationsDrawerView({
    required this.activeConversationId,
    required this.onConversationTapped,
    required this.onNewChatTapped,
    super.key,
  });

  /// {@macro conversations_drawer.activeConversationId}
  final String? activeConversationId;

  /// {@macro conversations_drawer.onConversationTapped}
  final ValueChanged<String> onConversationTapped;

  /// {@macro conversations_drawer.onNewChatTapped}
  final VoidCallback onNewChatTapped;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSpacing = context.appSpacing;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                appSpacing.md,
                appSpacing.md,
                appSpacing.md,
                appSpacing.xs,
              ),
              child: FilledButton.icon(
                onPressed: onNewChatTapped,
                icon: const Icon(Icons.add),
                label: Text(l10n.drawerNewChat),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: appSpacing.md,
                vertical: appSpacing.xs,
              ),
              child: Text(
                l10n.drawerSectionConversations,
                style: context.textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: BlocBuilder<ConversationsCubit, ConversationsState>(
                builder: (context, state) {
                  if (state.conversations.isEmpty) {
                    return _ConversationsEmptyState(message: l10n.drawerEmpty);
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: appSpacing.xs),
                    itemCount: state.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = state.conversations[index];
                      return ConversationTile(
                        conversation: conversation,
                        selected: conversation.id == activeConversationId,
                        onTap: () => onConversationTapped(conversation.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationsEmptyState extends StatelessWidget {
  const _ConversationsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final appSpacing = context.appSpacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: appSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textMuted,
          ),
        ),
      ),
    );
  }
}
