part of 'conversations_cubit.dart';

/// Categories of one-shot errors surfaced from [ConversationsCubit]
/// for the view to display.
enum ConversationsTransientError {
  /// Renaming a conversation failed in the storage layer.
  renameFailed,

  /// Moving a conversation between folders failed.
  moveFailed,

  /// Creating a folder failed in the storage layer.
  folderCreateFailed,

  /// Renaming a folder failed in the storage layer.
  folderRenameFailed,
}

/// {@template conversations_state}
/// State managed by [ConversationsCubit].
/// {@endtemplate}
final class ConversationsState extends Equatable {
  /// {@macro conversations_state}
  const ConversationsState({
    this.conversations = const [],
    this.folders = const [],
    this.transientError,
  });

  /// All conversations ordered by [Conversation.updatedAt] descending,
  /// as observed from [ConversationsRepository.watchConversations].
  final List<Conversation> conversations;

  /// All folders ordered by [Folder.createdAt] ascending, as observed
  /// from [ConversationsRepository.watchFolders].
  final List<Folder> folders;

  /// A transient error to surface to the user (e.g. via snackbar).
  /// Cleared by the view by calling [ConversationsCubit] once observed.
  final ConversationsTransientError? transientError;

  ConversationsState copyWith({
    List<Conversation>? conversations,
    List<Folder>? folders,
    ConversationsTransientError? transientError,
    bool clearTransientError = false,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      folders: folders ?? this.folders,
      transientError:
          clearTransientError ? null : transientError ?? this.transientError,
    );
  }

  @override
  List<Object?> get props => [conversations, folders, transientError];
}
