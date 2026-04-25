import 'package:chat_client/chat_client.dart';

/// {@template chat_client_exception}
/// Base class for all [ChatClient] related exceptions.
/// {@endtemplate}
abstract class ChatClientException implements Exception {
  /// {@macro chat_client_exception}
  const ChatClientException(this.error);

  /// The underlying error that was caught.
  final Object error;
}

/// {@template connect_exception}
/// Thrown when a [ChatClient] fails to open a connection to the backend.
/// {@endtemplate}
class ConnectException extends ChatClientException {
  /// {@macro connect_exception}
  const ConnectException(super.error);
}

/// {@template disconnect_exception}
/// Thrown when a [ChatClient] fails to close its connection.
/// {@endtemplate}
class DisconnectException extends ChatClientException {
  /// {@macro disconnect_exception}
  const DisconnectException(super.error);
}

/// {@template send_exception}
/// Thrown when a [ChatClient] fails to send a message.
/// {@endtemplate}
class SendException extends ChatClientException {
  /// {@macro send_exception}
  const SendException(super.error);
}

/// {@template message_too_large_exception}
/// Thrown when a message exceeds the implementation's maximum payload size.
/// {@endtemplate}
class MessageTooLargeException extends SendException {
  /// {@macro message_too_large_exception}
  const MessageTooLargeException(super.error);
}
