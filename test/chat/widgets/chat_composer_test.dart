import 'package:ask_ai_app/chat/widgets/chat_composer.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group(ChatComposer, () {
    Future<void> pumpComposer(
      WidgetTester tester, {
      required ValueChanged<String> onSubmit,
      bool inFlight = false,
    }) {
      return tester.pumpApp(
        Scaffold(
          body: ChatComposer(onSubmit: onSubmit, inFlight: inFlight),
        ),
      );
    }

    testWidgets('fires onSubmit with the typed text on send tap', (
      tester,
    ) async {
      final submitted = <String>[];
      await pumpComposer(tester, onSubmit: submitted.add);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(submitted, ['hello']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('fires onSubmit on the keyboard send action', (tester) async {
      final submitted = <String>[];
      await pumpComposer(tester, onSubmit: submitted.add);

      await tester.enterText(find.byType(TextField), 'via keyboard');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(submitted, ['via keyboard']);
    });

    testWidgets('does not fire onSubmit when text is blank', (tester) async {
      var calls = 0;
      await pumpComposer(tester, onSubmit: (_) => calls++);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('does not fire onSubmit while inFlight is true', (
      tester,
    ) async {
      var calls = 0;
      await pumpComposer(
        tester,
        onSubmit: (_) => calls++,
        inFlight: true,
      );

      await tester.enterText(find.byType(TextField), 'queued');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(calls, 0);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'queued',
      );
    });

    testWidgets('shows the in-flight indicator and hides the icon button', (
      tester,
    ) async {
      await pumpComposer(tester, onSubmit: (_) {}, inFlight: true);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('shows an enabled send icon when idle', (tester) async {
      await pumpComposer(tester, onSubmit: (_) {});

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNotNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('localizes the composer hint', (tester) async {
      late final BuildContext capturedContext;
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return ChatComposer(onSubmit: (_) {}, inFlight: false);
            },
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
