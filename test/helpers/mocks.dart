import 'package:chat_repository/chat_repository.dart';
import 'package:mocktail/mocktail.dart';

/// A no-op [ChatRepository] suitable as a default in widget tests that do
/// not interact with chat behavior. The default `incomingMessages` stream
/// is empty and `connect`/`disconnect`/`send` complete immediately.
class FakeChatRepository extends Fake implements ChatRepository {
  @override
  Stream<String> get incomingMessages => const Stream.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> send(String message) async {}
}

/// Mockable [ChatRepository] for tests that need to stub specific methods.
class MockChatRepository extends Mock implements ChatRepository {}
