import 'package:chat_client/chat_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeChatClient extends Fake implements ChatClient {}

void main() {
  group(ChatClient, () {
    test('can be implemented', () {
      expect(_FakeChatClient(), isA<ChatClient>());
    });
  });
}
