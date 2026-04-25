import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/counter/counter.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({required this.chatRepository, super.key});

  final ChatRepository chatRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: chatRepository,
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CounterPage(),
      ),
    );
  }
}
