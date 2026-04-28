import 'package:conversations_client/conversations_client.dart';

/// {@template conversations_client_exception}
/// Base class for all [ConversationsClient] related exceptions.
/// {@endtemplate}
abstract class ConversationsClientException implements Exception {
  /// {@macro conversations_client_exception}
  const ConversationsClientException(this.error);

  /// The underlying error that was caught.
  final Object error;
}

/// {@template storage_exception}
/// Thrown when a [ConversationsClient] operation fails at the storage
/// layer (e.g. the underlying database raised an error).
/// {@endtemplate}
class StorageException extends ConversationsClientException {
  /// {@macro storage_exception}
  const StorageException(super.error);
}
