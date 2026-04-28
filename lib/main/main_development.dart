import 'package:ask_ai_app/app/app.dart';
import 'package:ask_ai_app/main/bootstrap/bootstrap.dart';
import 'package:ask_ai_app/main/bootstrap/environment.dart';
import 'package:ask_ai_app/main/bootstrap/storage.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:drift_conversations_client/drift_conversations_client.dart';
import 'package:web_socket_chat_client/web_socket_chat_client.dart';

Future<void> main() async {
  final conversationsRepository = ConversationsRepository(
    client: DriftConversationsClient(executor: openConversationsDatabase()),
  );
  await bootstrap(
    () => App(
      conversationsRepository: conversationsRepository,
      chatRepositoryFactory: (_) => ChatRepository(
        chatClient: WebSocketChatClient(
          endpoint: Uri.parse(Environment.webSocketEchoEndpoint),
        ),
      ),
    ),
  );
}
