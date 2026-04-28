import 'package:ask_ai_app/app/bloc/app_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:conversations_repository/conversations_repository.dart';
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

/// A no-op [ConversationsRepository] suitable as a default in widget
/// tests that do not interact with persistence. All read streams emit a
/// single empty list; all writes complete immediately.
class FakeConversationsRepository extends Fake
    implements ConversationsRepository {
  @override
  Stream<List<Conversation>> watchConversations() =>
      Stream<List<Conversation>>.value(const []);

  @override
  Stream<List<Folder>> watchFolders() =>
      Stream<List<Folder>>.value(const []);

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream<List<Message>>.value(const []);

  @override
  Future<String?> readMetadata(String key) async => null;

  @override
  Future<void> writeMetadata({required String key, String? value}) async {}
}

/// Mockable [ConversationsRepository] for tests that need to stub
/// specific methods.
class MockConversationsRepository extends Mock
    implements ConversationsRepository {}

/// Mockable [AppBloc] for widget tests that need to assert dispatched
/// events or stub state transitions.
class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}
