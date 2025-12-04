import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/routes/app_router.dart';
import 'src/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://jnommzjbrttevoobdkiu.supabase.co', // Ganti dengan URL Supabase Anda
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impub21tempicnR0ZXZvb2Jka2l1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4MjM5NzQsImV4cCI6MjA4MDM5OTk3NH0.qSZXBoBs9kCCe8B0ivx9hy8TfYr7shjiDjx_cUdgDj0', // Ganti dengan ANON KEY Supabase Anda
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Reservasi Meja Restoran',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID')],
    );
  }
}