import 'package:conversations_client/conversations_client.dart';
import 'package:test/test.dart';

void main() {
  group(ConversationsClientException, () {
    final error = Exception('Oops');
    final exceptions = <ConversationsClientException>[
      StorageException(error),
    ];

    for (final exception in exceptions) {
      test('${exception.runtimeType} can instantiate', () {
        expect(exception, isA<ConversationsClientException>());
        expect(exception, isA<Exception>());
        expect(exception.error, same(error));
        expect(exception.toString().isNotEmpty, isTrue);
      });
    }
  });
}
