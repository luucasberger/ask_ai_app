import 'dart:async';

import 'package:ask_ai_app/app/registry/chat_repository_registry.dart';
import 'package:chat_client/chat_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  group(ChatRepositoryRegistry, () {
    late Map<String, MockChatRepository> repos;
    late Map<String, StreamController<String>> controllers;
    late List<(String, String)> echoes;

    ChatRepositoryRegistry buildRegistry() => ChatRepositoryRegistry(
      factory: (id) {
        final repo = repos[id] = MockChatRepository();
        final controller = controllers[id] =
            StreamController<String>.broadcast();
        when(() => repo.incomingMessages).thenAnswer(
          (_) => controller.stream,
        );
        when(repo.connect).thenAnswer((_) async {});
        when(repo.disconnect).thenAnswer((_) async {});
        return repo;
      },
      onEcho: (id, text) => echoes.add((id, text)),
    );

    setUp(() {
      repos = {};
      controllers = {};
      echoes = [];
    });

    tearDown(() async {
      for (final c in controllers.values) {
        await c.close();
      }
    });

    group('obtain', () {
      test('lazily creates and connects a repository', () async {
        final registry = buildRegistry();

        final repo = await registry.obtain('a');

        expect(repo, isNotNull);
        verify(repos['a']!.connect).called(1);
      });

      test('returns the same repository on subsequent calls', () async {
        final registry = buildRegistry();

        final first = await registry.obtain('a');
        final second = await registry.obtain('a');

        expect(identical(first, second), isTrue);
        verify(repos['a']!.connect).called(1);
      });

      test('forwards incoming messages to onEcho with the conversation id',
          () async {
        final registry = buildRegistry();
        await registry.obtain('a');
        await registry.obtain('b');

        controllers['a']!.add('hello');
        controllers['b']!.add('world');
        await Future<void>.delayed(Duration.zero);

        expect(echoes, [('a', 'hello'), ('b', 'world')]);
      });

      test('drops the entry when the connect call fails', () async {
        ChatRepositoryRegistry? registry;
        var calls = 0;
        registry = ChatRepositoryRegistry(
          factory: (id) {
            calls++;
            final repo = repos[id] = MockChatRepository();
            final controller = controllers[id] =
                StreamController<String>.broadcast();
            when(() => repo.incomingMessages).thenAnswer(
              (_) => controller.stream,
            );
            when(repo.disconnect).thenAnswer((_) async {});
            if (calls == 1) {
              when(repo.connect).thenThrow(ConnectException('boom'));
            } else {
              when(repo.connect).thenAnswer((_) async {});
            }
            return repo;
          },
          onEcho: (_, __) {},
        );

        await expectLater(
          () => registry!.obtain('a'),
          throwsA(isA<ConnectException>()),
        );
        await registry.obtain('a');

        expect(calls, 2);
      });
    });

    group('dispose', () {
      test('cancels the subscription and disconnects the repository',
          () async {
        final registry = buildRegistry();
        await registry.obtain('a');

        await registry.dispose('a');

        verify(repos['a']!.disconnect).called(1);
        controllers['a']!.add('arrives-after-dispose');
        await Future<void>.delayed(Duration.zero);
        expect(echoes, isEmpty);
      });

      test('is a no-op for unknown ids', () async {
        final registry = buildRegistry();

        await registry.dispose('unknown');

        expect(repos, isEmpty);
      });
    });

    group('disposeAll', () {
      test('disposes every registered repository', () async {
        final registry = buildRegistry();
        await registry.obtain('a');
        await registry.obtain('b');

        await registry.disposeAll();

        verify(repos['a']!.disconnect).called(1);
        verify(repos['b']!.disconnect).called(1);
      });
    });
  });
}
