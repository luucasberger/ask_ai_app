import 'package:conversations_client/conversations_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FakeConversationsClient extends Fake implements ConversationsClient {}

void main() {
  group(ConversationsClient, () {
    test('can be implemented', () {
      expect(_FakeConversationsClient(), isA<ConversationsClient>());
    });
  });
}
