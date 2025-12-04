import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(supabaseProvider));
});

class AuthState {
  final bool isLoading;
  final Session? session;
  final User? user;
  final String? role;
  final String? errorMessage;

  AuthState({
    this.isLoading = true,
    this.session,
    this.user,
    this.role,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    Session? session,
    User? user,
    String? role,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      user: user ?? this.user,
      role: role ?? this.role,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient client;

  AuthNotifier(this.client) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await client.auth.getSession().then((value) {
        if (value.error != null) {
          throw Exception(value.error?.message);
        }
        
        final session = value.data.session;
        if (session != null) {
          _loadUserData(session.user.id);
        } else {
          state = state.copyWith(isLoading: false);
        }
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _loadUserData(String userId) async {
    final {data, error} = await client
        .from('users')
        .select('role')
        .eq('id', userId)
        .single();

    if (error == null && data != null) {
      state = state.copyWith(
        isLoading: false,
        role: data['role'] as String,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data user',
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final {data, error} = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (error != null) throw Exception(error.message);
      
      await _loadUserData(data.user!.id);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final {data, error} = await client.auth.signUp(
        email: email,
        password: password,
        options: AuthOptions( {
          'name': name,
          'phone': phone,
        }),
      );

      if (error != null) throw Exception(error.message);
      
      // Insert ke tabel users
      final {error: insertError} = await client.from('users').insert({
        'id': data.user!.id,
        'name': name,
        'phone_number': phone,
        'role': 'user',
      });

      if (insertError != null) throw Exception(insertError.message);
      
      await _loadUserData(data.user!.id);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    state = const AuthState();
    _init();
  }
}