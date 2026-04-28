import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/app/bloc/app_bloc.dart';
import 'package:ask_ai_app/app/registry/chat_repository_registry.dart';
import 'package:ask_ai_app/chat/chat.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({
    required this.conversationsRepository,
    required this.chatRepositoryFactory,
    super.key,
  });

  final ConversationsRepository conversationsRepository;
  final ChatRepositoryFactory chatRepositoryFactory;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ConversationsRepository>.value(
          value: conversationsRepository,
        ),
        RepositoryProvider<ChatRepositoryRegistry>(
          create: (_) => ChatRepositoryRegistry(factory: chatRepositoryFactory),
          dispose: (registry) => unawaited(registry.disposeAll()),
        ),
      ],
      child: BlocProvider(
        create: (context) => AppBloc(
          conversationsRepository: context.read<ConversationsRepository>(),
          chatRepositoryRegistry: context.read<ChatRepositoryRegistry>(),
        )..add(const AppStarted()),
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ChatPage(),
          ),
        ),
      ),
    );
  }
}
