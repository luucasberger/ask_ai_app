import 'package:conversations_client/conversations_client.dart';

/// {@template conversations_client}
/// Transport-agnostic interface for persisting AskAI conversations,
/// folders, and messages.
///
/// Implementations are responsible for the storage layer (e.g. SQLite
/// via drift). Read operations expose live [Stream]s so subscribers
/// re-render when the underlying data changes; write operations
/// resolve when the change has been durably persisted.
///
/// Storage failures surface as [StorageException].
/// {@endtemplate}
abstract class ConversationsClient {
  /// Stream of all [Conversation]s ordered by [Conversation.updatedAt]
  /// descending (most recently touched first).
  Stream<List<Conversation>> watchConversations();

  /// Stream of all [Folder]s ordered by [Folder.createdAt] ascending.
  Stream<List<Folder>> watchFolders();

  /// Stream of [Message]s belonging to the conversation identified by
  /// [conversationId], ordered by [Message.sentAt] ascending
  /// (oldest first).
  Stream<List<Message>> watchMessages(String conversationId);

  /// Creates a new [Conversation] and returns it.
  ///
  /// [folderId] determines the parent folder; pass `null` for the
  /// implicit "Uncategorized" bucket. [title] is typically derived from
  /// the user's first message but may be any non-empty string.
  Future<Conversation> createConversation({
    required String title,
    String? folderId,
  });

  /// Updates the [Conversation.title] of the conversation identified
  /// by [id].
  ///
  /// Does **not** bump [Conversation.updatedAt] — only [appendMessage]
  /// touches it, so the conversation list ordering reflects message
  /// activity rather than metadata edits.
  Future<void> renameConversation({
    required String id,
    required String title,
  });

  /// Permanently removes the conversation identified by [id], along
  /// with every [Message] inside it.
  Future<void> deleteConversation(String id);

  /// Moves the conversation identified by [id] into the [Folder]
  /// identified by [folderId], or to "Uncategorized" if [folderId]
  /// is `null`.
  Future<void> moveConversation({
    required String id,
    String? folderId,
  });

  /// Appends a new [Message] to the conversation identified by
  /// [conversationId] and returns the persisted entity, including
  /// its assigned id and timestamp.
  ///
  /// The conversation's [Conversation.updatedAt] is bumped to match
  /// the new message's timestamp.
  Future<Message> appendMessage({
    required String conversationId,
    required MessageRole role,
    required String text,
  });

  /// Creates a new [Folder] with the given [name] and returns it.
  Future<Folder> createFolder(String name);

  /// Updates the [Folder.name] of the folder identified by [id].
  Future<void> renameFolder({
    required String id,
    required String name,
  });

  /// Permanently removes the folder identified by [id]. Cascades:
  /// every [Conversation] inside the folder (and every [Message]
  /// inside those conversations) is also deleted.
  Future<void> deleteFolder(String id);

  /// Returns the number of conversations currently inside the folder
  /// identified by [folderId]. Used to populate the folder-delete
  /// confirmation copy.
  Future<int> conversationCountInFolder(String folderId);

  /// Reads a free-form metadata value associated with [key], or
  /// `null` if no value has been written.
  Future<String?> readMetadata(String key);

  /// Writes a free-form metadata value. Passing a `null` [value]
  /// removes the entry for [key].
  Future<void> writeMetadata({
    required String key,
    String? value,
  });
}
