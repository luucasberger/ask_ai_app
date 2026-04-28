import 'package:conversations_client/conversations_client.dart';

/// {@template conversations_repository}
/// Bridges a [ConversationsClient] to AskAI feature blocs.
///
/// The repository is a thin pass-through today; it exists so feature
/// code depends on a single repository abstraction rather than a
/// concrete client implementation, leaving room to add caching,
/// debouncing, or derived streams later without touching consumers.
/// {@endtemplate}
class ConversationsRepository {
  /// {@macro conversations_repository}
  ConversationsRepository({
    required ConversationsClient client,
  }) : _client = client;

  final ConversationsClient _client;

  /// Stream of all [Conversation]s ordered by [Conversation.updatedAt]
  /// descending.
  ///
  /// See [ConversationsClient.watchConversations].
  Stream<List<Conversation>> watchConversations() =>
      _client.watchConversations();

  /// Stream of all [Folder]s ordered by [Folder.createdAt] ascending.
  ///
  /// See [ConversationsClient.watchFolders].
  Stream<List<Folder>> watchFolders() => _client.watchFolders();

  /// Stream of [Message]s belonging to the conversation identified by
  /// [conversationId], ordered by [Message.sentAt] ascending.
  ///
  /// See [ConversationsClient.watchMessages].
  Stream<List<Message>> watchMessages(String conversationId) =>
      _client.watchMessages(conversationId);

  /// Creates a new [Conversation].
  ///
  /// See [ConversationsClient.createConversation].
  Future<Conversation> createConversation({
    required String title,
    String? folderId,
  }) => _client.createConversation(title: title, folderId: folderId);

  /// Renames the conversation identified by [id].
  ///
  /// See [ConversationsClient.renameConversation].
  Future<void> renameConversation({
    required String id,
    required String title,
  }) => _client.renameConversation(id: id, title: title);

  /// Deletes the conversation identified by [id].
  ///
  /// See [ConversationsClient.deleteConversation].
  Future<void> deleteConversation(String id) => _client.deleteConversation(id);

  /// Moves the conversation identified by [id] into a folder, or to
  /// "Uncategorized" when [folderId] is `null`.
  ///
  /// See [ConversationsClient.moveConversation].
  Future<void> moveConversation({required String id, String? folderId}) =>
      _client.moveConversation(id: id, folderId: folderId);

  /// Appends a new [Message] to the conversation identified by
  /// [conversationId].
  ///
  /// See [ConversationsClient.appendMessage].
  Future<Message> appendMessage({
    required String conversationId,
    required MessageRole role,
    required String text,
  }) => _client.appendMessage(
    conversationId: conversationId,
    role: role,
    text: text,
  );

  /// Creates a new [Folder].
  ///
  /// See [ConversationsClient.createFolder].
  Future<Folder> createFolder(String name) => _client.createFolder(name);

  /// Renames the folder identified by [id].
  ///
  /// See [ConversationsClient.renameFolder].
  Future<void> renameFolder({required String id, required String name}) =>
      _client.renameFolder(id: id, name: name);

  /// Deletes the folder identified by [id], cascading to every
  /// conversation and message inside it.
  ///
  /// See [ConversationsClient.deleteFolder].
  Future<void> deleteFolder(String id) => _client.deleteFolder(id);

  /// Returns the number of conversations inside the folder identified
  /// by [folderId].
  ///
  /// See [ConversationsClient.conversationCountInFolder].
  Future<int> conversationCountInFolder(String folderId) =>
      _client.conversationCountInFolder(folderId);

  /// Reads a metadata value for [key].
  ///
  /// See [ConversationsClient.readMetadata].
  Future<String?> readMetadata(String key) => _client.readMetadata(key);

  /// Writes (or removes, when [value] is `null`) a metadata value.
  ///
  /// See [ConversationsClient.writeMetadata].
  Future<void> writeMetadata({required String key, String? value}) =>
      _client.writeMetadata(key: key, value: value);
}
