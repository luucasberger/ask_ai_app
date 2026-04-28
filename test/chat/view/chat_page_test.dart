import 'dart:async';

import 'package:ask_ai_app/app/bloc/app_bloc.dart';
import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:ask_ai_app/chat/view/chat_page.dart';
import 'package:ask_ai_app/chat/widgets/chat_bubble.dart';
import 'package:ask_ai_app/chat/widgets/chat_composer.dart';
import 'package:ask_ai_app/chat/widgets/typewriter_text.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chat_client/chat_client.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(MessageRole.user);
    registerFallbackValue(const AppConversationActivated('_'));
    registerFallbackValue(const AppNewConversationRequested());
    registerFallbackValue(const AppFirstMessageSubmitted('_'));
    registerFallbackValue(const AppStreamingCompleted('_'));
    registerFallbackValue(const AppTransientErrorCleared());
  });

  Conversation buildConversation({
    String id = 'c0',
    String title = 'A conversation',
  }) {
    return Conversation(
      id: id,
      title: title,
      createdAt: DateTime.utc(2026, 4, 27),
      updatedAt: DateTime.utc(2026, 4, 27),
    );
  }

  Message buildMessage({
    String id = 'm0',
    String conversationId = 'c0',
    MessageRole role = MessageRole.user,
    String text = 'hi',
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      role: role,
      text: text,
      sentAt: DateTime.utc(2026, 4, 27),
    );
  }

  late MockAppBloc appBloc;
  late MockConversationsRepository conversationsRepository;

  setUp(() {
    appBloc = MockAppBloc();
    conversationsRepository = MockConversationsRepository();
    when(conversationsRepository.watchConversations).thenAnswer(
      (_) => Stream<List<Conversation>>.value(const []),
    );
    when(() => conversationsRepository.watchMessages(any())).thenAnswer(
      (_) => Stream<List<Message>>.value(const []),
    );
    when(() => appBloc.obtainChatRepository(any())).thenAnswer(
      (_) async => FakeChatRepository(),
    );
  });

  void seedAppState(AppState state) {
    whenListen(
      appBloc,
      const Stream<AppState>.empty(),
      initialState: state,
    );
  }

  group(ChatPage, () {
    testWidgets('renders $ChatView under a $ConversationsRepository', (
      tester,
    ) async {
      seedAppState(const AppState());

      await tester.pumpApp(
        ChatPage(),
        appBloc: appBloc,
        conversationsRepository: conversationsRepository,
      );
      await tester.pump();

      expect(find.byType(ChatView), findsOneWidget);
    });
  });

  group(ChatView, () {
    testWidgets(
      'renders the empty-state body when no conversation is active',
      (tester) async {
        seedAppState(const AppState());

        late final BuildContext capturedContext;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return ChatPage();
            },
          ),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        expect(
          find.text(capturedContext.l10n.chatEmptyTitle),
          findsOneWidget,
        );
        expect(find.byType(ChatComposer), findsOneWidget);
        expect(find.byType(ChatBubble), findsNothing);
      },
    );

    testWidgets(
      'falls back to the localized AppBar title when no conversation is active',
      (tester) async {
        seedAppState(const AppState());

        late final BuildContext capturedContext;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return ChatPage();
            },
          ),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text(capturedContext.l10n.chatAppBarTitle),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows the active conversation title in the AppBar',
      (tester) async {
        when(conversationsRepository.watchConversations).thenAnswer(
          (_) => Stream<List<Conversation>>.value([
            buildConversation(id: 'c-1', title: 'Lunch plans'),
          ]),
        );
        seedAppState(const AppState(activeConversationId: 'c-1'));

        await tester.pumpApp(
          ChatPage(),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Lunch plans'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'composer dispatches $AppFirstMessageSubmitted in the empty state',
      (tester) async {
        seedAppState(const AppState());

        await tester.pumpApp(
          ChatPage(),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'hi');
        await tester.tap(
          find.descendant(
            of: find.byType(ChatComposer),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pump();

        verify(
          () => appBloc.add(AppFirstMessageSubmitted('hi')),
        ).called(1);
      },
    );

    testWidgets(
      'renders one $ChatBubble per message when a conversation is active',
      (tester) async {
        when(() => conversationsRepository.watchMessages('c-1')).thenAnswer(
          (_) => Stream<List<Message>>.value([
            buildMessage(id: 'm-1', conversationId: 'c-1', text: 'first'),
            buildMessage(
              id: 'm-2',
              conversationId: 'c-1',
              role: MessageRole.assistant,
              text: 'second',
            ),
          ]),
        );
        seedAppState(const AppState(activeConversationId: 'c-1'));

        await tester.pumpApp(
          ChatPage(),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        expect(find.byType(ChatBubble), findsNWidgets(2));
        expect(find.text('first'), findsOneWidget);
        expect(find.text('second'), findsOneWidget);
      },
    );

    testWidgets(
      'composer dispatches $ChatMessageSubmitted in an active conversation',
      (tester) async {
        when(() => conversationsRepository.watchMessages('c-1')).thenAnswer(
          (_) => Stream<List<Message>>.value(const []),
        );
        when(
          () => conversationsRepository.appendMessage(
            conversationId: any(named: 'conversationId'),
            role: any(named: 'role'),
            text: any(named: 'text'),
          ),
        ).thenAnswer(
          (_) async => buildMessage(),
        );
        seedAppState(const AppState(activeConversationId: 'c-1'));

        await tester.pumpApp(
          ChatPage(),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'hi');
        await tester.tap(
          find.descendant(
            of: find.byType(ChatComposer),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pump();

        verify(
          () => conversationsRepository.appendMessage(
            conversationId: 'c-1',
            role: MessageRole.user,
            text: 'hi',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'reveals the streaming assistant message via $TypewriterText',
      (tester) async {
        when(() => conversationsRepository.watchMessages('c-1')).thenAnswer(
          (_) => Stream<List<Message>>.value([
            buildMessage(
              id: 'm-9',
              conversationId: 'c-1',
              role: MessageRole.assistant,
              text: 'streamed',
            ),
          ]),
        );
        seedAppState(
          const AppState(
            activeConversationId: 'c-1',
            streamingMessageId: 'm-9',
          ),
        );

        await tester.pumpApp(
          ChatPage(),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        expect(find.byType(TypewriterText), findsOneWidget);

        for (var i = 0; i < 'streamed'.length + 1; i++) {
          await tester.pump(Duration(milliseconds: 30));
        }

        verify(() => appBloc.add(AppStreamingCompleted('m-9'))).called(1);
      },
    );

    testWidgets(
      'flips the composer to in-flight when streamingMessageId is set',
      (tester) async {
        when(() => conversationsRepository.watchMessages('c-1')).thenAnswer(
          (_) => Stream<List<Message>>.value(const []),
        );
        whenListen(
          appBloc,
          Stream<AppState>.fromIterable([
            const AppState(
              activeConversationId: 'c-1',
              streamingMessageId: 'm-9',
            ),
          ]),
          initialState: const AppState(activeConversationId: 'c-1'),
        );

        await tester.pumpApp(
          ChatPage(),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(ChatComposer),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows a snackbar and clears the transient error for app-level errors',
      (tester) async {
        whenListen(
          appBloc,
          Stream<AppState>.fromIterable([
            const AppState(transientError: AppTransientError.connectionFailed),
          ]),
          initialState: const AppState(),
        );

        late final BuildContext capturedContext;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return ChatPage();
            },
          ),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.text(capturedContext.l10n.chatErrorConnectionFailed),
          findsOneWidget,
        );
        verify(() => appBloc.add(AppTransientErrorCleared())).called(1);
      },
    );

    testWidgets(
      'tapping the drawer "new chat" CTA dispatches '
      '$AppNewConversationRequested',
      (tester) async {
        seedAppState(const AppState(activeConversationId: 'c-1'));
        when(() => conversationsRepository.watchMessages('c-1')).thenAnswer(
          (_) => Stream<List<Message>>.value(const []),
        );

        await tester.pumpApp(
          ChatPage(),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        verify(
          () => appBloc.add(const AppNewConversationRequested()),
        ).called(1);
      },
    );

    testWidgets(
      'tapping a drawer tile dispatches $AppConversationActivated',
      (tester) async {
        when(conversationsRepository.watchConversations).thenAnswer(
          (_) => Stream<List<Conversation>>.value([
            buildConversation(id: 'c-1', title: 'Lunch plans'),
            buildConversation(id: 'c-2', title: 'Dinner plans'),
          ]),
        );
        seedAppState(const AppState(activeConversationId: 'c-1'));
        when(() => conversationsRepository.watchMessages('c-1')).thenAnswer(
          (_) => Stream<List<Message>>.value(const []),
        );

        await tester.pumpApp(
          ChatPage(),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dinner plans'));
        await tester.pump();

        verify(
          () => appBloc.add(const AppConversationActivated('c-2')),
        ).called(1);
      },
    );
  });

  group('error message mapping', () {
    for (final error in AppTransientError.values) {
      testWidgets('app-level error $error renders a localized snackbar', (
        tester,
      ) async {
        whenListen(
          appBloc,
          Stream<AppState>.fromIterable([AppState(transientError: error)]),
          initialState: const AppState(),
        );

        late final BuildContext capturedContext;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return ChatPage();
            },
          ),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();
        await tester.pump();

        final l10n = capturedContext.l10n;
        final expected = switch (error) {
          AppTransientError.persistenceFailed =>
            l10n.chatErrorPersistenceFailed,
          AppTransientError.connectionFailed => l10n.chatErrorConnectionFailed,
          AppTransientError.sendFailed => l10n.chatErrorSendFailed,
          AppTransientError.messageTooLarge => l10n.chatErrorMessageTooLarge,
        };
        expect(find.text(expected), findsOneWidget);
      });
    }

    for (final error in ChatTransientError.values) {
      testWidgets('chat-level error $error renders a localized snackbar', (
        tester,
      ) async {
        seedAppState(const AppState(activeConversationId: 'c-1'));

        // Throw on append so the chat bloc emits the requested transient
        // error when we trigger a send.
        late StreamController<List<Message>> messages;
        messages = StreamController<List<Message>>.broadcast();
        when(() => conversationsRepository.watchMessages('c-1')).thenAnswer(
          (_) => messages.stream,
        );
        addTearDown(messages.close);

        switch (error) {
          case ChatTransientError.persistenceFailed:
            when(
              () => conversationsRepository.appendMessage(
                conversationId: any(named: 'conversationId'),
                role: any(named: 'role'),
                text: any(named: 'text'),
              ),
            ).thenThrow(StorageException('boom'));
          case ChatTransientError.connectionFailed:
            when(
              () => conversationsRepository.appendMessage(
                conversationId: any(named: 'conversationId'),
                role: any(named: 'role'),
                text: any(named: 'text'),
              ),
            ).thenAnswer((_) async => buildMessage());
            when(() => appBloc.obtainChatRepository(any())).thenThrow(
              ConnectException('no'),
            );
          case ChatTransientError.sendFailed:
          case ChatTransientError.messageTooLarge:
            final repo = MockChatRepository();
            when(repo.connect).thenAnswer((_) async {});
            when(repo.disconnect).thenAnswer((_) async {});
            when(() => repo.incomingMessages)
                .thenAnswer((_) => const Stream<String>.empty());
            when(() => repo.send(any())).thenThrow(
              error == ChatTransientError.messageTooLarge
                  ? MessageTooLargeException('too large')
                  : SendException('nope'),
            );
            when(
              () => conversationsRepository.appendMessage(
                conversationId: any(named: 'conversationId'),
                role: any(named: 'role'),
                text: any(named: 'text'),
              ),
            ).thenAnswer((_) async => buildMessage());
            when(() => appBloc.obtainChatRepository(any())).thenAnswer(
              (_) async => repo,
            );
        }

        late final BuildContext capturedContext;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return ChatPage();
            },
          ),
          appBloc: appBloc,
          conversationsRepository: conversationsRepository,
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'hi');
        await tester.tap(
          find.descendant(
            of: find.byType(ChatComposer),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();

        final l10n = capturedContext.l10n;
        final expected = switch (error) {
          ChatTransientError.persistenceFailed =>
            l10n.chatErrorPersistenceFailed,
          ChatTransientError.connectionFailed => l10n.chatErrorConnectionFailed,
          ChatTransientError.sendFailed => l10n.chatErrorSendFailed,
          ChatTransientError.messageTooLarge => l10n.chatErrorMessageTooLarge,
        };
        expect(find.text(expected), findsOneWidget);
      });
    }
  });
}
