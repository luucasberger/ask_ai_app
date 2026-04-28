import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/cubit/conversations_cubit.dart';
import 'package:ask_ai_app/conversations/widgets/widgets.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Provides a [ConversationsCubit] for the drawer surface and renders
/// the [ConversationsDrawerView].
class ConversationsDrawer extends StatelessWidget {
  /// {@macro conversations_drawer_view}
  const ConversationsDrawer({
    required this.activeConversationId,
    required this.onConversationTapped,
    required this.onNewChatTapped,
    required this.onRenameRequested,
    required this.onDeleteRequested,
    required this.onMoveRequested,
    required this.onMoveToNewFolderRequested,
    required this.onNewFolderRequested,
    required this.onFolderRenameRequested,
    required this.onFolderDeleteRequested,
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

  /// {@template conversations_drawer.onRenameRequested}
  /// Invoked when the user picks **Rename** from the long-press
  /// context menu of a conversation row.
  /// {@endtemplate}
  final ValueChanged<Conversation> onRenameRequested;

  /// {@template conversations_drawer.onDeleteRequested}
  /// Invoked when the user picks **Delete** from the long-press
  /// context menu of a conversation row.
  /// {@endtemplate}
  final ValueChanged<Conversation> onDeleteRequested;

  /// {@template conversations_drawer.onMoveRequested}
  /// Invoked when the user picks an existing folder (or
  /// "Uncategorized") from the **Move to folder…** submenu of a
  /// conversation row. The folder id is `null` when the user picks
  /// "Uncategorized".
  /// {@endtemplate}
  final void Function(Conversation conversation, String? folderId)
      onMoveRequested;

  /// {@template conversations_drawer.onMoveToNewFolderRequested}
  /// Invoked when the user picks **New folder…** from the
  /// **Move to folder…** submenu of a conversation row. The caller
  /// is responsible for prompting for the folder name and chaining
  /// the create-and-move.
  /// {@endtemplate}
  final ValueChanged<Conversation> onMoveToNewFolderRequested;

  /// {@template conversations_drawer.onNewFolderRequested}
  /// Invoked when the user taps the drawer's "+" action to create a
  /// new folder.
  /// {@endtemplate}
  final VoidCallback onNewFolderRequested;

  /// {@template conversations_drawer.onFolderRenameRequested}
  /// Invoked when the user picks **Rename** from the long-press
  /// context menu of a folder row.
  /// {@endtemplate}
  final ValueChanged<Folder> onFolderRenameRequested;

  /// {@template conversations_drawer.onFolderDeleteRequested}
  /// Invoked when the user picks **Delete** from the long-press
  /// context menu of a folder row.
  /// {@endtemplate}
  final ValueChanged<Folder> onFolderDeleteRequested;

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
        onRenameRequested: onRenameRequested,
        onDeleteRequested: onDeleteRequested,
        onMoveRequested: onMoveRequested,
        onMoveToNewFolderRequested: onMoveToNewFolderRequested,
        onNewFolderRequested: onNewFolderRequested,
        onFolderRenameRequested: onFolderRenameRequested,
        onFolderDeleteRequested: onFolderDeleteRequested,
      ),
    );
  }
}

/// {@template conversations_drawer_view}
/// The drawer surface that renders the conversation history.
///
/// Layout, top-to-bottom:
/// 1. **New chat** CTA in the header.
/// 2. **Folders** section header with a `+` action that creates a new
///    folder.
/// 3. The list of folders (each an [FolderTile] expansion with its
///    nested conversations), shown only when folders exist.
/// 4. **Uncategorized** section header followed by every conversation
///    that does not belong to a folder, shown only when there are
///    uncategorized conversations and at least one folder exists.
///    When no folders exist, the loose conversations are listed
///    directly without a redundant section header.
/// 5. An empty-state message when no folders and no conversations
///    exist.
/// {@endtemplate}
class ConversationsDrawerView extends StatelessWidget {
  /// {@macro conversations_drawer_view}
  const ConversationsDrawerView({
    required this.activeConversationId,
    required this.onConversationTapped,
    required this.onNewChatTapped,
    required this.onRenameRequested,
    required this.onDeleteRequested,
    required this.onMoveRequested,
    required this.onMoveToNewFolderRequested,
    required this.onNewFolderRequested,
    required this.onFolderRenameRequested,
    required this.onFolderDeleteRequested,
    super.key,
  });

  /// {@macro conversations_drawer.activeConversationId}
  final String? activeConversationId;

  /// {@macro conversations_drawer.onConversationTapped}
  final ValueChanged<String> onConversationTapped;

  /// {@macro conversations_drawer.onNewChatTapped}
  final VoidCallback onNewChatTapped;

  /// {@macro conversations_drawer.onRenameRequested}
  final ValueChanged<Conversation> onRenameRequested;

  /// {@macro conversations_drawer.onDeleteRequested}
  final ValueChanged<Conversation> onDeleteRequested;

  /// {@macro conversations_drawer.onMoveRequested}
  final void Function(Conversation conversation, String? folderId)
      onMoveRequested;

  /// {@macro conversations_drawer.onMoveToNewFolderRequested}
  final ValueChanged<Conversation> onMoveToNewFolderRequested;

  /// {@macro conversations_drawer.onNewFolderRequested}
  final VoidCallback onNewFolderRequested;

  /// {@macro conversations_drawer.onFolderRenameRequested}
  final ValueChanged<Folder> onFolderRenameRequested;

  /// {@macro conversations_drawer.onFolderDeleteRequested}
  final ValueChanged<Folder> onFolderDeleteRequested;

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
            Expanded(
              child: BlocBuilder<ConversationsCubit, ConversationsState>(
                builder: (context, state) {
                  final folders = state.folders;
                  final byFolder = <String, List<Conversation>>{};
                  final uncategorized = <Conversation>[];
                  for (final conversation in state.conversations) {
                    final folderId = conversation.folderId;
                    if (folderId == null) {
                      uncategorized.add(conversation);
                    } else {
                      byFolder
                          .putIfAbsent(folderId, () => [])
                          .add(conversation);
                    }
                  }

                  final showEmptyState =
                      folders.isEmpty && state.conversations.isEmpty;
                  final showUncategorizedHeader =
                      folders.isNotEmpty && uncategorized.isNotEmpty;

                  return ListView(
                    padding: EdgeInsets.symmetric(vertical: appSpacing.xs),
                    children: [
                      _SectionHeader(
                        title: l10n.drawerSectionFolders,
                        trailing: IconButton(
                          tooltip: l10n.drawerNewFolderTooltip,
                          icon: const Icon(Icons.create_new_folder_outlined),
                          onPressed: onNewFolderRequested,
                        ),
                      ),
                      for (final folder in folders)
                        FolderTile(
                          key: ValueKey('folder-${folder.id}'),
                          folder: folder,
                          onRenameSelected: () =>
                              onFolderRenameRequested(folder),
                          onDeleteSelected: () =>
                              onFolderDeleteRequested(folder),
                          children: [
                            for (final conversation in byFolder[folder.id] ??
                                const <Conversation>[])
                              ConversationTile(
                                key:
                                    ValueKey('conversation-${conversation.id}'),
                                conversation: conversation,
                                folders: folders,
                                selected:
                                    conversation.id == activeConversationId,
                                onTap: () =>
                                    onConversationTapped(conversation.id),
                                onRenameSelected: () =>
                                    onRenameRequested(conversation),
                                onDeleteSelected: () =>
                                    onDeleteRequested(conversation),
                                onMoveSelected: (folderId) =>
                                    onMoveRequested(conversation, folderId),
                                onMoveToNewFolderSelected: () =>
                                    onMoveToNewFolderRequested(conversation),
                              ),
                          ],
                        ),
                      if (showUncategorizedHeader)
                        _SectionHeader(title: l10n.drawerSectionUncategorized),
                      for (final conversation in uncategorized)
                        ConversationTile(
                          key: ValueKey('conversation-${conversation.id}'),
                          conversation: conversation,
                          folders: folders,
                          selected: conversation.id == activeConversationId,
                          onTap: () => onConversationTapped(conversation.id),
                          onRenameSelected: () => onRenameRequested(
                            conversation,
                          ),
                          onDeleteSelected: () => onDeleteRequested(
                            conversation,
                          ),
                          onMoveSelected: (folderId) => onMoveRequested(
                            conversation,
                            folderId,
                          ),
                          onMoveToNewFolderSelected: () =>
                              onMoveToNewFolderRequested(conversation),
                        ),
                      if (showEmptyState)
                        _ConversationsEmptyState(message: l10n.drawerEmpty),
                    ],
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final appSpacing = context.appSpacing;
    final trailing = this.trailing;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        appSpacing.md,
        appSpacing.xs,
        trailing == null ? appSpacing.md : appSpacing.xs,
        appSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: context.textTheme.labelMedium),
          ),
          if (trailing != null) trailing,
        ],
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        appSpacing.lg,
        appSpacing.xlg,
        appSpacing.lg,
        appSpacing.lg,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.appColors.textMuted,
        ),
      ),
    );
  }
}
