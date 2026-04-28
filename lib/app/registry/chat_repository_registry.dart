import 'dart:async';

import 'package:chat_repository/chat_repository.dart';

/// Signature for a function that constructs a fresh [ChatRepository]
/// for the given conversation id. Each call must return a *new*
/// instance — the registry owns the lifecycle of each repository.
typedef ChatRepositoryFactory = ChatRepository Function(String conversationId);

/// {@template echo_received_callback}
/// Invoked once per echoed assistant message, with the conversation id
/// the echo belongs to and the message text.
/// {@endtemplate}
typedef EchoReceivedCallback = void Function(
  String conversationId,
  String text,
);

/// {@template chat_repository_registry}
/// App-level registry of [ChatRepository] instances keyed by
/// conversation id.
///
/// Each conversation gets its own WebSocket connection so the echo
/// for one conversation cannot bleed into another. The registry
/// outlives any individual chat page, so an in-flight echo continues
/// to land even after the user navigates away from the conversation
/// that issued the send.
/// {@endtemplate}
class ChatRepositoryRegistry {
  /// {@macro chat_repository_registry}
  ChatRepositoryRegistry({
    required ChatRepositoryFactory factory,
    required EchoReceivedCallback onEcho,
  })  : _factory = factory,
        _onEcho = onEcho;

  final ChatRepositoryFactory _factory;
  final EchoReceivedCallback _onEcho;

  final Map<String, ChatRepository> _repositories = {};
  final Map<String, StreamSubscription<String>> _subscriptions = {};

  /// Returns the [ChatRepository] for [conversationId], lazily
  /// creating and connecting it on first request.
  ///
  /// Subsequent calls with the same id return the same instance.
  /// Connection errors are surfaced; the entry is removed so the next
  /// call retries.
  Future<ChatRepository> obtain(String conversationId) async {
    final existing = _repositories[conversationId];
    if (existing != null) return existing;

    final repository = _factory(conversationId);
    _repositories[conversationId] = repository;
    try {
      await repository.connect();
    } catch (_) {
      _repositories.remove(conversationId);
      rethrow;
    }
    _subscriptions[conversationId] = repository.incomingMessages.listen(
      (text) => _onEcho(conversationId, text),
    );
    return repository;
  }

  /// Disposes the connection for [conversationId] (if any).
  Future<void> dispose(String conversationId) async {
    await _subscriptions.remove(conversationId)?.cancel();
    final repository = _repositories.remove(conversationId);
    await repository?.disconnect();
  }

  /// Disposes every connection. Called once during app shutdown.
  Future<void> disposeAll() async {
    final ids = _repositories.keys.toList(growable: false);
    await Future.wait(ids.map(dispose));
  }
}
