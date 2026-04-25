import 'package:chat_client/chat_client.dart';
import 'package:equatable/equatable.dart';

/// {@template chat_event}
/// Base type for events emitted by a [ChatClient].
/// {@endtemplate}
sealed class ChatEvent extends Equatable {
  /// {@macro chat_event}
  const ChatEvent();

  @override
  List<Object?> get props => const [];
}

/// {@template chat_connected}
/// Emitted when the [ChatClient] connection has been established.
/// {@endtemplate}
final class ChatConnected extends ChatEvent {
  /// {@macro chat_connected}
  const ChatConnected();
}

/// {@template chat_message_received}
/// Emitted when a message is received from the [ChatClient] backend.
/// {@endtemplate}
final class ChatMessageReceived extends ChatEvent {
  /// {@macro chat_message_received}
  const ChatMessageReceived(this.message);

  /// The text payload received from the backend.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// {@template chat_disconnected}
/// Emitted when the [ChatClient] connection has been closed, either
/// intentionally (via [ChatClient.disconnect]) or by the backend (e.g. an
/// idle timeout).
/// {@endtemplate}
final class ChatDisconnected extends ChatEvent {
  /// {@macro chat_disconnected}
  const ChatDisconnected();
}

/// {@template chat_error_occurred}
/// Emitted when a transport-level error occurs on the [ChatClient]
/// connection.
/// {@endtemplate}
final class ChatErrorOccurred extends ChatEvent {
  /// {@macro chat_error_occurred}
  const ChatErrorOccurred(this.error);

  /// The underlying error.
  final Object error;

  @override
  List<Object?> get props => [error];
}
