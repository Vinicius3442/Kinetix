import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'data/repositories/demo_repository.dart';
import 'data/repositories/kinetix_repository.dart';
import 'data/repositories/supabase_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  KinetixRepository repo;
  if (Env.isDemo) {
    repo = DemoRepository();
  } else {
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
    repo = SupabaseRepository(Supabase.instance.client);
  }

  runApp(ProviderScope(
    overrides: [repositoryProvider.overrideWithValue(repo)],
    child: const KinetixApp(),
  ));
}

class KinetixApp extends ConsumerWidget {
  const KinetixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kinetix',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(),
      themeMode: ThemeMode.dark,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
