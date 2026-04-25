import 'dart:async';
import 'dart:convert';

import 'package:chat_client/chat_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_chat_client/web_socket_chat_client.dart';

class _MockWebSocketChannel extends Mock implements WebSocketChannel {}

class _MockWebSocketSink extends Mock implements WebSocketSink {}

class _FakeChannel {
  _FakeChannel({
    Future<void>? ready,
    Stream<dynamic>? stream,
  }) : channel = _MockWebSocketChannel(),
       sink = _MockWebSocketSink(),
       _streamController = StreamController<dynamic>.broadcast() {
    final source = stream ?? _streamController.stream;
    when(() => channel.ready).thenAnswer((_) => ready ?? Future<void>.value());
    when(() => channel.stream).thenAnswer((_) => source);
    when(() => channel.sink).thenReturn(sink);
    when(sink.close).thenAnswer((_) async {});
    when(() => sink.add(any<dynamic>())).thenAnswer((_) {});
  }

  final _MockWebSocketChannel channel;
  final _MockWebSocketSink sink;
  final StreamController<dynamic> _streamController;

  void emitMessage(dynamic data) => _streamController.add(data);
  void emitError(Object error) => _streamController.addError(error);
  Future<void> closeStream() => _streamController.close();
}

void main() {
  final endpoint = Uri.parse('wss://echo.websocket.org');

  group(WebSocketChatClient, () {
    test('implements $ChatClient', () {
      expect(WebSocketChatClient(endpoint: endpoint), isA<ChatClient>());
    });

    test('exposes a 64KB max message size', () {
      expect(WebSocketChatClient.maxMessageBytes, equals(64 * 1024));
    });

    group('connect', () {
      test('opens the channel and emits $ChatConnected', () async {
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );
        final events = <ChatEvent>[];
        final subscription = client.events.listen(events.add);

        await client.connect();
        await Future<void>.delayed(Duration.zero);

        expect(events, orderedEquals([ChatConnected()]));
        await subscription.cancel();
        await client.disconnect();
      });

      test('uses the configured endpoint', () async {
        Uri? captured;
        final fake = _FakeChannel();
        final backup = Uri.parse('wss://echo-websocket.fly.dev');
        final client = WebSocketChatClient(
          endpoint: backup,
          channelFactory: (uri) {
            captured = uri;
            return fake.channel;
          },
        );

        await client.connect();

        expect(captured, equals(backup));
        await client.disconnect();
      });

      test('is idempotent when already connected', () async {
        var factoryCalls = 0;
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) {
            factoryCalls++;
            return fake.channel;
          },
        );

        await client.connect();
        await client.connect();

        expect(factoryCalls, equals(1));
        await client.disconnect();
      });

      test(
        'throws $ConnectException when the channel fails to be ready',
        () async {
          final error = StateError('boom');
          final fake = _FakeChannel(ready: Future<void>.error(error));
          final client = WebSocketChatClient(
            endpoint: endpoint,
            channelFactory: (_) => fake.channel,
          );

          await expectLater(
            client.connect,
            throwsA(
              isA<ConnectException>().having((e) => e.error, 'error', error),
            ),
          );
        },
      );
    });

    group('events', () {
      test('emits $ChatMessageReceived for incoming string data', () async {
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );
        final events = <ChatEvent>[];
        final subscription = client.events.listen(events.add);

        await client.connect();
        fake.emitMessage('hello');
        await Future<void>.delayed(Duration.zero);

        expect(
          events,
          containsAllInOrder(<ChatEvent>[
            ChatConnected(),
            ChatMessageReceived('hello'),
          ]),
        );
        await subscription.cancel();
        await client.disconnect();
      });

      test('decodes incoming List<int> data as UTF-8', () async {
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );
        final events = <ChatEvent>[];
        final subscription = client.events.listen(events.add);

        await client.connect();
        fake.emitMessage(utf8.encode('hi'));
        await Future<void>.delayed(Duration.zero);

        expect(events.last, equals(ChatMessageReceived('hi')));
        await subscription.cancel();
        await client.disconnect();
      });

      test('ignores incoming data of other types', () async {
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );
        final events = <ChatEvent>[];
        final subscription = client.events.listen(events.add);

        await client.connect();
        fake.emitMessage(42);
        await Future<void>.delayed(Duration.zero);

        expect(events, orderedEquals([ChatConnected()]));
        await subscription.cancel();
        await client.disconnect();
      });

      test('emits $ChatErrorOccurred on transport errors', () async {
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );
        final error = Exception('boom');
        final events = <ChatEvent>[];
        final subscription = client.events.listen(events.add);

        await client.connect();
        fake.emitError(error);
        await Future<void>.delayed(Duration.zero);

        expect(events.last, equals(ChatErrorOccurred(error)));
        await subscription.cancel();
        await client.disconnect();
      });

      test(
        'emits $ChatDisconnected when the server closes the stream',
        () async {
          final fake = _FakeChannel();
          final client = WebSocketChatClient(
            endpoint: endpoint,
            channelFactory: (_) => fake.channel,
          );
          final events = <ChatEvent>[];
          final subscription = client.events.listen(events.add);

          await client.connect();
          await fake.closeStream();
          await Future<void>.delayed(Duration.zero);

          expect(events.last, equals(ChatDisconnected()));
          await subscription.cancel();
        },
      );
    });

    group('send', () {
      test('forwards the message to the sink', () async {
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );

        await client.connect();
        await client.send('hello');

        verify(() => fake.sink.add('hello')).called(1);
        await client.disconnect();
      });

      test('throws $SendException when not connected', () async {
        final client = WebSocketChatClient(endpoint: endpoint);

        await expectLater(
          () => client.send('hi'),
          throwsA(isA<SendException>()),
        );
      });

      test('throws $MessageTooLargeException for messages over 64KB', () async {
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );
        final tooBig = 'a' * (WebSocketChatClient.maxMessageBytes + 1);

        await client.connect();

        await expectLater(
          () => client.send(tooBig),
          throwsA(isA<MessageTooLargeException>()),
        );
        await client.disconnect();
      });

      test('wraps sink errors in $SendException', () async {
        final fake = _FakeChannel();
        final error = StateError('sink closed');
        when(() => fake.sink.add(any<dynamic>())).thenThrow(error);
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );

        await client.connect();

        await expectLater(
          () => client.send('hi'),
          throwsA(
            isA<SendException>().having((e) => e.error, 'error', error),
          ),
        );
        await client.disconnect();
      });
    });

    group('disconnect', () {
      test('closes the sink and emits $ChatDisconnected', () async {
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );
        final events = <ChatEvent>[];
        final subscription = client.events.listen(events.add);

        await client.connect();
        await client.disconnect();
        await Future<void>.delayed(Duration.zero);

        verify(fake.sink.close).called(1);
        expect(events.last, equals(ChatDisconnected()));
        await subscription.cancel();
      });

      test('is a no-op when not connected', () async {
        final fake = _FakeChannel();
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );

        await client.disconnect();

        verifyNever(fake.sink.close);
      });

      test(
        'only emits $ChatDisconnected once even if the stream also closes',
        () async {
          final fake = _FakeChannel();
          final client = WebSocketChatClient(
            endpoint: endpoint,
            channelFactory: (_) => fake.channel,
          );
          final events = <ChatEvent>[];
          final subscription = client.events.listen(events.add);

          await client.connect();
          await client.disconnect();
          await fake.closeStream();
          await Future<void>.delayed(Duration.zero);

          final disconnectedCount = events.whereType<ChatDisconnected>().length;
          expect(disconnectedCount, 1);
          await subscription.cancel();
        },
      );

      test('wraps sink close errors in $DisconnectException', () async {
        final fake = _FakeChannel();
        final error = StateError('close failed');
        when(fake.sink.close).thenThrow(error);
        final client = WebSocketChatClient(
          endpoint: endpoint,
          channelFactory: (_) => fake.channel,
        );

        await client.connect();

        await expectLater(
          client.disconnect,
          throwsA(
            isA<DisconnectException>().having((e) => e.error, 'error', error),
          ),
        );
      });
    });
  });
}
