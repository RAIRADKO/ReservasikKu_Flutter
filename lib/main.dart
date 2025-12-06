import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/routes/app_router.dart';
import 'src/common/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // GUNAKAN KREDENSIAL YANG SAMA DENGAN .env
  await Supabase.initialize(
    url: 'https://opwpjzervgijjtcawzhe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9wd3BqemVydmdpamp0Y2F3emhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMTY1ODcsImV4cCI6MjA4MDU5MjU4N30.zty35nDZPWaF5RS1B6rxlJB73FgN_GCBPv9DcNJE14I',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerConfig = ref.watch(routerProvider);
    
    return MaterialApp.router(
      routerConfig: routerConfig,
      title: 'Reservasi Meja Restoran',
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID')],
    );
  }
}