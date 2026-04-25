import 'package:chat_client/chat_client.dart';
import 'package:test/test.dart';

void main() {
  group(ChatEvent, () {
    group(ChatConnected, () {
      test('supports value equality', () {
        expect(ChatConnected(), equals(ChatConnected()));
      });

      test('props is empty', () {
        expect(ChatConnected().props, isEmpty);
      });
    });

    group(ChatMessageReceived, () {
      test('exposes the message payload', () {
        expect(ChatMessageReceived('hello').message, 'hello');
      });

      test('supports value equality', () {
        expect(ChatMessageReceived('hi'), equals(ChatMessageReceived('hi')));
      });

      test('different messages are not equal', () {
        expect(
          ChatMessageReceived('a'),
          isNot(equals(ChatMessageReceived('b'))),
        );
      });

      test('props includes the message', () {
        expect(ChatMessageReceived('hi').props, ['hi']);
      });
    });

    group(ChatDisconnected, () {
      test('supports value equality', () {
        expect(ChatDisconnected(), equals(ChatDisconnected()));
      });

      test('props is empty', () {
        expect(ChatDisconnected().props, isEmpty);
      });
    });

    group(ChatErrorOccurred, () {
      test('exposes the underlying error', () {
        final error = Exception('boom');
        expect(ChatErrorOccurred(error).error, same(error));
      });

      test('supports value equality on identical errors', () {
        final error = Exception('boom');
        expect(ChatErrorOccurred(error), equals(ChatErrorOccurred(error)));
      });

      test('props includes the error', () {
        final error = Exception('boom');
        expect(ChatErrorOccurred(error).props, orderedEquals([error]));
      });
    });

    test('variants are not equal to each other', () {
      expect(ChatConnected(), isNot(equals(ChatDisconnected())));
    });
  });
}
