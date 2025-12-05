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

  AuthNotifier(this.client) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final session = client.auth.currentSession;
      if (session != null) {
        await _loadUserData(session.user.id);
        state = state.copyWith(
          session: session,
          user: session.user,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final response = await client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      state = state.copyWith(
        isLoading: false,
        role: response['role'] as String,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data user',
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await _loadUserData(response.user!.id);
      state = state.copyWith(
        session: response.session,
        user: response.user,
      );
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
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      if (response.user != null) {
        // Insert ke tabel users
        await client.from('users').insert({
          'id': response.user!.id,
          'name': name,
          'phone_number': phone,
          'role': 'user',
        });
        
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    state = AuthState();
    _init();
  }
}