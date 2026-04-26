import 'package:ask_ai_app/chat/widgets/typewriter_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group(TypewriterText, () {
    testWidgets('reveals text one character at a time', (tester) async {
      await tester.pumpApp(
        TypewriterText(
          text: 'hi',
          onCompleted: () {},
        ),
      );

      await tester.pump(Duration(milliseconds: 30));
      expect(find.text('h'), findsOneWidget);

      await tester.pump(Duration(milliseconds: 30));
      expect(find.text('hi'), findsOneWidget);
    });

    testWidgets('invokes onCompleted exactly once after the reveal finishes', (
      tester,
    ) async {
      var completedCount = 0;
      await tester.pumpApp(
        TypewriterText(
          text: 'ab',
          onCompleted: () => completedCount++,
        ),
      );

      // Two ticks reveal the two chars; a third tick triggers completion.
      await tester.pump(Duration(milliseconds: 30));
      await tester.pump(Duration(milliseconds: 30));
      await tester.pump(Duration(milliseconds: 30));
      expect(completedCount, 1);

      // Subsequent pumps must not re-fire.
      await tester.pump(Duration(milliseconds: 100));
      expect(completedCount, 1);
    });

    testWidgets('applies the provided text style', (tester) async {
      await tester.pumpApp(
        TypewriterText(
          text: 'x',
          style: TextStyle(color: Color(0xFFFF0000)),
          onCompleted: () {},
        ),
      );

      await tester.pump(Duration(milliseconds: 30));
      final rendered = tester.widget<Text>(find.text('x'));
      expect(rendered.style?.color, Color(0xFFFF0000));
    });

    testWidgets('cancels the timer when disposed mid-reveal', (tester) async {
      var completedCount = 0;
      await tester.pumpApp(
        TypewriterText(
          text: 'hello world',
          onCompleted: () => completedCount++,
        ),
      );
      await tester.pump(Duration(milliseconds: 30));

      await tester.pumpApp(SizedBox.shrink());
      await tester.pump(Duration(seconds: 1));

      expect(completedCount, 0);
    });
  });
}
