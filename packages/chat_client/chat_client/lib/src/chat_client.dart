import 'package:chat_client/chat_client.dart';

/// {@template chat_client}
/// Transport-agnostic interface for sending messages and receiving replies
/// from a chat backend.
///
/// Implementations are responsible for opening a connection, queuing or
/// rejecting writes while disconnected, and translating transport events
/// into [ChatEvent]s.
/// {@endtemplate}
abstract class ChatClient {
  /// Stream of events from the chat backend.
  ///
  /// Emits a [ChatConnected] when the connection is established, a
  /// [ChatMessageReceived] for each incoming message, a [ChatDisconnected]
  /// when the connection is closed (including idle drops), and a
  /// [ChatErrorOccurred] for any transport error.
  Stream<ChatEvent> get events;

  /// Opens a connection to the chat backend.
  ///
  /// Idempotent: completes successfully if already connected.
  /// Throws [ConnectException] if the connection cannot be established.
  Future<void> connect();

  /// Closes the open connection.
  ///
  /// Idempotent: completes successfully if not connected.
  /// Throws [DisconnectException] if the connection cannot be closed cleanly.
  Future<void> disconnect();

  /// Sends [message] over the open connection.
  ///
  /// Throws [MessageTooLargeException] if [message] exceeds the
  /// implementation's maximum size. Throws [SendException] for other
  /// send failures (e.g. not connected).
  Future<void> send(String message);
}
