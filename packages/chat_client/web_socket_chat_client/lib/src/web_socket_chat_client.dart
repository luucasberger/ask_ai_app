import 'dart:async';
import 'dart:convert';

import 'package:chat_client/chat_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Type definition that opens a [WebSocketChannel] for a given [Uri].
typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

/// {@template web_socket_chat_client}
/// A WebSocket-backed implementation of [ChatClient].
///
/// The [WebSocketChatClient.new] constructor requires the [Uri] of the
/// WebSocket endpoint — the value is provided at the composition root
/// (typically from a `--dart-define-from-file` env file). A custom
/// [WebSocketChannelFactory] can be injected to substitute the transport
/// in tests.
/// {@endtemplate}
class WebSocketChatClient implements ChatClient {
  /// {@macro web_socket_chat_client}
  WebSocketChatClient({
    required Uri endpoint,
    WebSocketChannelFactory channelFactory = WebSocketChannel.connect,
  }) : _endpoint = endpoint,
       _channelFactory = channelFactory;

  /// Maximum message size in bytes accepted by the echo server.
  static const int maxMessageBytes = 64 * 1024;

  final Uri _endpoint;
  final WebSocketChannelFactory _channelFactory;
  final StreamController<ChatEvent> _events =
      StreamController<ChatEvent>.broadcast();

  WebSocketChannel? _channel;
  // Subscription is cancelled in `disconnect` and `_handleDone`.
  // ignore: cancel_subscriptions
  StreamSubscription<dynamic>? _subscription;

  @override
  Stream<ChatEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    if (_channel != null) return;
    try {
      final channel = _channelFactory(_endpoint);
      await channel.ready;
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleData,
        onError: _handleError,
        onDone: _handleDone,
      );
      _events.add(const ChatConnected());
    } on ChatClientException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ConnectException(error), stackTrace);
    }
  }

  @override
  Future<void> disconnect() async {
    final subscription = _subscription;
    final channel = _channel;
    if (channel == null) return;
    _subscription = null;
    _channel = null;
    try {
      await subscription?.cancel();
      await channel.sink.close();
      _events.add(const ChatDisconnected());
    } on ChatClientException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(DisconnectException(error), stackTrace);
    }
  }

  @override
  Future<void> send(String message) async {
    try {
      final channel = _channel;
      if (channel == null) {
        throw const SendException('chat client is not connected');
      }
      if (utf8.encode(message).length > maxMessageBytes) {
        throw const MessageTooLargeException(
          'message exceeds $maxMessageBytes bytes',
        );
      }
      channel.sink.add(message);
    } on ChatClientException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(SendException(error), stackTrace);
    }
  }

  void _handleData(dynamic data) {
    if (data is String) {
      _events.add(ChatMessageReceived(data));
    } else if (data is List<int>) {
      _events.add(ChatMessageReceived(utf8.decode(data)));
    }
  }

  void _handleError(Object error) {
    _events.add(ChatErrorOccurred(error));
  }

  void _handleDone() {
    if (_channel == null) return;
    _channel = null;
    _subscription = null;
    _events.add(const ChatDisconnected());
  }
}
