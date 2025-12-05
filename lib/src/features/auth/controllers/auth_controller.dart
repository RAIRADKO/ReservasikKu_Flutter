import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

// State untuk form register
class RegisterFormState {
  final String name;
  final String email;
  final String password;
  final String phone;
  final bool isLoading;

  RegisterFormState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.phone = '',
    this.isLoading = false,
  });

  bool get isValid =>
      name.isNotEmpty &&
      email.isNotEmpty &&
      password.length >= 6 &&
      phone.length >= 10;

  RegisterFormState copyWith({
    String? name,
    String? email,
    String? password,
    String? phone,
    bool? isLoading,
  }) {
    return RegisterFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final registerFormProvider = StateProvider.autoDispose<RegisterFormState>((ref) {
  return RegisterFormState();
});

// Auth Provider
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
      print('❌ Init error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
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
      print('❌ Load user data error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signIn(String email, String password) async {
    print('🔐 SignIn started');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      print('   Calling Supabase signInWithPassword...');
      
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('   Response received');
      print('   User: ${response.user?.id}');
      print('   Session: ${response.session != null}');

      if (response.user != null) {
        await _loadUserData(response.user!.id);
        state = state.copyWith(
          session: response.session,
          user: response.user,
        );
        print('✅ SignIn completed successfully');
      } else {
        print('⚠️ SignIn returned no user');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login gagal, tidak ada user',
        );
      }
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      print('❌ SignIn error: $e');
      String errorMsg = e.toString();
      
      // Parse error untuk user-friendly message
      if (errorMsg.contains('Failed to fetch')) {
        errorMsg = 'Koneksi ke server gagal. Periksa koneksi internet Anda.';
      } else if (errorMsg.contains('Network')) {
        errorMsg = 'Masalah jaringan. Coba lagi.';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    print('📝 SignUp started');
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

      print('   SignUp response received');

      if (response.user != null) {
        // Insert ke users table
        await client.from('users').insert({
          'id': response.user!.id,
          'name': name,
          'phone_number': phone,
          'role': 'user',
        });

        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
        );
        print('✅ SignUp completed successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Registrasi gagal',
        );
      }
    } on AuthException catch (e) {
      print('❌ SignUp AuthException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      print('❌ SignUp error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      state = AuthState();
      await _init();
    } catch (e) {
      print('❌ SignOut error: $e');
    }
  }
}