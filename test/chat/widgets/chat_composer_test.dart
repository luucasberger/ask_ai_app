import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:ask_ai_app/chat/widgets/chat_composer.dart';
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

  late _MockChatBloc bloc;

  setUp(() {
    bloc = _MockChatBloc();
  });

  Future<void> pumpComposer(WidgetTester tester) {
    return tester.pumpApp(
      BlocProvider<ChatBloc>.value(
        value: bloc,
        child: Scaffold(body: ChatComposer()),
      ),
    );
  }

  group(ChatComposer, () {
    testWidgets('disables the text field while connecting', (tester) async {
      when(() => bloc.state).thenReturn(
        ChatState(status: ChatStatus.connecting),
      );

      await pumpComposer(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });

    testWidgets('enables the text field when ready', (tester) async {
      when(() => bloc.state).thenReturn(
        ChatState(status: ChatStatus.ready),
      );

      await pumpComposer(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isTrue);
    });

    testWidgets('dispatches $ChatMessageSubmitted on tap', (tester) async {
      when(() => bloc.state).thenReturn(
        ChatState(status: ChatStatus.ready),
      );

      await pumpComposer(tester);
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      verify(() => bloc.add(ChatMessageSubmitted('hello'))).called(1);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets(
      'dispatches $ChatMessageSubmitted on the keyboard send action',
      (tester) async {
        when(() => bloc.state).thenReturn(
          ChatState(status: ChatStatus.ready),
        );

        await pumpComposer(tester);
        await tester.enterText(find.byType(TextField), 'via keyboard');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump();

        verify(
          () => bloc.add(ChatMessageSubmitted('via keyboard')),
        ).called(1);
      },
    );

    testWidgets(
      'does not dispatch on the keyboard send action while a response '
      'is in flight and preserves the typed text',
      (tester) async {
        when(() => bloc.state).thenReturn(
          ChatState(
            status: ChatStatus.ready,
            awaitingResponse: true,
          ),
        );

        await pumpComposer(tester);
        await tester.enterText(find.byType(TextField), 'queued message');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump();

        verifyNever(() => bloc.add(any(that: isA<ChatMessageSubmitted>())));
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'queued message',
        );
      },
    );

    testWidgets('does not dispatch when text is blank', (tester) async {
      when(() => bloc.state).thenReturn(
        ChatState(status: ChatStatus.ready),
      );

      await pumpComposer(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      verifyNever(() => bloc.add(any(that: isA<ChatMessageSubmitted>())));
    });

    testWidgets(
      'shows the in-flight indicator while a response is in flight',
      (tester) async {
        when(() => bloc.state).thenReturn(
          ChatState(
            status: ChatStatus.ready,
            awaitingResponse: true,
          ),
        );

        await pumpComposer(tester);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(IconButton), findsNothing);
      },
    );

    testWidgets('shows an enabled send icon when ready and idle', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        ChatState(status: ChatStatus.ready),
      );

      await pumpComposer(tester);

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNotNull);
    });

    testWidgets('disables the send icon while not ready', (tester) async {
      when(() => bloc.state).thenReturn(
        ChatState(status: ChatStatus.connecting),
      );

      await pumpComposer(tester);

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('localizes the composer hint', (tester) async {
      when(() => bloc.state).thenReturn(
        ChatState(status: ChatStatus.ready),
      );

      late final BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ChatBloc>.value(
          value: bloc,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return ChatComposer();
              },
            ),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.decoration?.hintText,
        capturedContext.l10n.chatComposerHint,
      );
    });
  });
}
