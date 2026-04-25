import 'package:ask_ai_app/app/app.dart';
import 'package:ask_ai_app/main/bootstrap/bootstrap.dart';
import 'package:ask_ai_app/main/bootstrap/environment.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:web_socket_chat_client/web_socket_chat_client.dart';

Future<void> main() async {
  final chatRepository = ChatRepository(
    chatClient: WebSocketChatClient(
      endpoint: Uri.parse(Environment.webSocketEchoEndpoint),
    ),
  );
  await bootstrap(() => App(chatRepository: chatRepository));
}
