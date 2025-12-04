import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static late SupabaseClient _client;

  static void initialize(String url, String anonKey) {
    _client = SupabaseClient(url, anonKey);
  }

  static SupabaseClient get client => _client;
}