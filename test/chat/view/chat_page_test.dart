import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:ask_ai_app/chat/model/message.dart';
import 'package:ask_ai_app/chat/view/chat_page.dart';
import 'package:ask_ai_app/chat/widgets/chat_bubble.dart';
import 'package:ask_ai_app/chat/widgets/chat_composer.dart';
import 'package:ask_ai_app/chat/widgets/typewriter_text.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockChatBloc extends MockBloc<ChatEvent, ChatState>
    implements ChatBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(ChatStarted());
  });

  group(ChatPage, () {
    testWidgets('renders $ChatView under a $ChatBloc', (tester) async {
      await tester.pumpApp(ChatPage());
      await tester.pump();

      expect(find.byType(ChatView), findsOneWidget);
      expect(find.byType(ChatComposer), findsOneWidget);
    });
  });

  group(ChatView, () {
    late _MockChatBloc bloc;

    setUp(() => bloc = _MockChatBloc());

    Future<void> pumpView(WidgetTester tester) {
      return tester.pumpApp(
        BlocProvider<ChatBloc>.value(value: bloc, child: ChatView()),
      );
    }

    testWidgets('shows the localized $AppBar title', (tester) async {
      when(() => bloc.state).thenReturn(ChatState());

      late final BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ChatBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return ChatView();
            },
          ),
        ),
      );

      expect(
        find.text(capturedContext.l10n.chatAppBarTitle),
        findsOneWidget,
      );
    });

    testWidgets('renders the empty state when there are no messages', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        ChatState(status: ChatStatus.ready),
      );

      late final BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ChatBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return ChatView();
            },
          ),
        ),
      );

      expect(
        find.text(capturedContext.l10n.chatEmptyTitle),
        findsOneWidget,
      );
      expect(
        find.text(capturedContext.l10n.chatEmptyMessage),
        findsOneWidget,
      );
      expect(find.byType(ChatBubble), findsNothing);
    });

    testWidgets(
      'renders one $ChatBubble per message in newest-at-bottom order',
      (tester) async {
        when(() => bloc.state).thenReturn(
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.user, text: 'first'),
              Message(id: '1', role: MessageRole.assistant, text: 'second'),
            ],
          ),
        );

        await pumpView(tester);

        expect(find.byType(ChatBubble), findsNWidgets(2));
        expect(find.text('first'), findsOneWidget);
        expect(find.text('second'), findsOneWidget);
      },
    );

    testWidgets(
      'streams the assistant message marked by streamingMessageId',
      (tester) async {
        when(() => bloc.state).thenReturn(
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '7', role: MessageRole.assistant, text: 'streamed'),
            ],
            streamingMessageId: '7',
          ),
        );

        await pumpView(tester);

        expect(find.byType(TypewriterText), findsOneWidget);
      },
    );

    testWidgets(
      'dispatches $ChatStreamingCompleted when the typewriter finishes',
      (tester) async {
        whenListen(
          bloc,
          Stream<ChatState>.empty(),
          initialState: ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '7', role: MessageRole.assistant, text: 'hi'),
            ],
            streamingMessageId: '7',
          ),
        );

        await pumpView(tester);

        // Pump enough frames to walk through the typewriter and fire its
        // completion callback.
        for (var i = 0; i < 'hi'.length + 1; i++) {
          await tester.pump(Duration(milliseconds: 30));
        }

        verify(() => bloc.add(ChatStreamingCompleted('7'))).called(1);
      },
    );

    testWidgets('shows a snackbar with the connection-failed message', (
      tester,
    ) async {
      whenListen(
        bloc,
        Stream<ChatState>.fromIterable([
          ChatState(
            status: ChatStatus.error,
            transientError: ChatTransientError.connectionFailed,
          ),
        ]),
        initialState: ChatState(),
      );

      late final BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ChatBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return ChatView();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(capturedContext.l10n.chatErrorConnectionFailed),
        findsOneWidget,
      );
    });

    testWidgets('shows a snackbar with the send-failed message', (
      tester,
    ) async {
      whenListen(
        bloc,
        Stream<ChatState>.fromIterable([
          ChatState(
            status: ChatStatus.ready,
            transientError: ChatTransientError.sendFailed,
          ),
        ]),
        initialState: ChatState(status: ChatStatus.ready),
      );

      late final BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ChatBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return ChatView();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(capturedContext.l10n.chatErrorSendFailed),
        findsOneWidget,
      );
    });

    testWidgets('shows a snackbar with the message-too-large message', (
      tester,
    ) async {
      whenListen(
        bloc,
        Stream<ChatState>.fromIterable([
          ChatState(
            status: ChatStatus.ready,
            transientError: ChatTransientError.messageTooLarge,
          ),
        ]),
        initialState: ChatState(status: ChatStatus.ready),
      );

      late final BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ChatBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return ChatView();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(capturedContext.l10n.chatErrorMessageTooLarge),
        findsOneWidget,
      );
    });
  });
}
