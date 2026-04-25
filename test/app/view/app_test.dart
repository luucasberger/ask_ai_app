import 'package:ask_ai_app/app/app.dart';
import 'package:ask_ai_app/counter/counter.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  group('App', () {
    testWidgets('renders CounterPage', (tester) async {
      await tester.pumpApp(
        App(chatRepository: _MockChatRepository()),
      );
      expect(find.byType(CounterPage), findsOneWidget);
    });
  });
}
