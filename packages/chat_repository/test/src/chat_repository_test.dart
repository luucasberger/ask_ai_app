import 'dart:async';

import 'package:chat_client/chat_client.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockChatClient extends Mock implements ChatClient {}

void main() {
  late _MockChatClient chatClient;
  late ChatRepository repository;
  late StreamController<ChatEvent> events;

  setUp(() {
    chatClient = _MockChatClient();
    events = StreamController<ChatEvent>.broadcast();
    when(() => chatClient.events).thenAnswer((_) => events.stream);
    repository = ChatRepository(chatClient: chatClient);
  });

  tearDown(() => events.close());

  group(ChatRepository, () {
    test('can be instantiated with a $ChatClient', () {
      expect(repository, isNotNull);
    });

    group('incomingMessages', () {
      test('emits the text payload of $ChatMessageReceived events', () {
        expect(
          repository.incomingMessages,
          emitsInOrder(<String>['hello', 'world']),
        );
        events
          ..add(ChatConnected())
          ..add(ChatMessageReceived('hello'))
          ..add(ChatErrorOccurred('boom'))
          ..add(ChatMessageReceived('world'));
      });

      test('does not emit for non-message events', () async {
        final received = <String>[];
        final subscription = repository.incomingMessages.listen(received.add);

        events
          ..add(ChatConnected())
          ..add(ChatDisconnected())
          ..add(ChatErrorOccurred('boom'));
        await Future<void>.delayed(Duration.zero);

        expect(received, isEmpty);
        await subscription.cancel();
      });
    });

    group('connect', () {
      test('delegates to the chat client', () async {
        when(chatClient.connect).thenAnswer((_) async {});

        await repository.connect();

        verify(chatClient.connect).called(1);
      });
    });

    group('disconnect', () {
      test('delegates to the chat client', () async {
        when(chatClient.disconnect).thenAnswer((_) async {});

        await repository.disconnect();

        verify(chatClient.disconnect).called(1);
      });
    });

    group('send', () {
      test('delegates to the chat client', () async {
        when(() => chatClient.send(any())).thenAnswer((_) async {});

        await repository.send('hi');

        verify(() => chatClient.send('hi')).called(1);
      });

      test('propagates errors from the chat client', () async {
        when(
          () => chatClient.send(any()),
        ).thenThrow(SendException('not connected'));

        expect(
          () => repository.send('hi'),
          throwsA(isA<SendException>()),
        );
      });
    });
  });
}
