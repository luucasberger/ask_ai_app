import 'package:chat_client/chat_client.dart';

/// {@template chat_repository}
/// Bridges a [ChatClient] to AskAI feature blocs.
///
/// Filters raw [ChatEvent]s into the surfaces that the chat bloc actually
/// consumes: incoming assistant messages and connection status.
/// {@endtemplate}
class ChatRepository {
  /// {@macro chat_repository}
  ChatRepository({required ChatClient chatClient}) : _chatClient = chatClient;

  final ChatClient _chatClient;

  /// Stream of messages received from the chat backend.
  Stream<String> get incomingMessages => _chatClient.events
      .where((event) => event is ChatMessageReceived)
      .cast<ChatMessageReceived>()
      .map((event) => event.message);

  /// Opens the chat connection. See [ChatClient.connect].
  Future<void> connect() => _chatClient.connect();

  /// Closes the chat connection. See [ChatClient.disconnect].
  Future<void> disconnect() => _chatClient.disconnect();

  /// Sends a user [message] over the chat connection. See [ChatClient.send].
  Future<void> send(String message) => _chatClient.send(message);
}
