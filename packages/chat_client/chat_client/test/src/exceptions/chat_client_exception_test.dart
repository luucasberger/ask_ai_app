import 'package:chat_client/chat_client.dart';
import 'package:test/test.dart';

void main() {
  group(ChatClientException, () {
    final error = Exception('boom');
    final exceptions = <ChatClientException>[
      ConnectException(error),
      DisconnectException(error),
      SendException(error),
      MessageTooLargeException(error),
    ];

    for (final exception in exceptions) {
      test('${exception.runtimeType} can instantiate', () {
        expect(exception, isA<ChatClientException>());
        expect(exception, isA<Exception>());
        expect(exception.error, same(error));
        expect(exception.toString().isNotEmpty, isTrue);
      });
    }

    test('$MessageTooLargeException is a $SendException', () {
      expect(MessageTooLargeException(error), isA<SendException>());
    });
  });
}
