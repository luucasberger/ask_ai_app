import 'package:ask_ai_app/chat/model/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(Message, () {
    test('supports value equality', () {
      final a = Message(id: '1', role: MessageRole.user, text: 'hi');
      expect(a, equals(Message(id: '1', role: MessageRole.user, text: 'hi')));
      expect(
        a,
        isNot(equals(Message(id: '2', role: MessageRole.user, text: 'hi'))),
      );
    });
  });
}
