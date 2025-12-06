import 'dart:async';
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
  StreamSubscription? _authStateSubscription;

  AuthNotifier(this.client) : super(AuthState()) {
    _init();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    // Listen to Supabase auth state changes
    _authStateSubscription = client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('🔄 Auth state changed: $event');

      if (event == AuthChangeEvent.signedIn && session != null) {
        // User signed in
        _loadUserData(session.user.id).then((_) {
          state = state.copyWith(
            session: session,
            user: session.user,
            isLoading: false,
            errorMessage: null,
          );
        });
      } else if (event == AuthChangeEvent.signedOut) {
        // User signed out
        state = AuthState(isLoading: false);
      } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        // Token refreshed
        state = state.copyWith(
          session: session,
          user: session.user,
        );
      } else if (event == AuthChangeEvent.userUpdated && session != null) {
        // User updated
        state = state.copyWith(
          session: session,
          user: session.user,
        );
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
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
          isLoading: false,
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

      if (response.user != null && response.session != null) {
        await _loadUserData(response.user!.id);
        state = state.copyWith(
          session: response.session,
          user: response.user,
          isLoading: false,
          errorMessage: null,
        );
        print('✅ SignIn completed successfully');
      } else {
        print('⚠️ SignIn returned no user or session');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login gagal, tidak ada user atau session',
        );
      }
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.message}');
      String errorMsg = e.message;
      
      // Parse error untuk user-friendly message
      if (errorMsg.contains('Invalid login credentials') || 
          errorMsg.contains('Invalid credentials')) {
        errorMsg = 'Email atau password salah';
      } else if (errorMsg.contains('Email not confirmed')) {
        errorMsg = 'Email belum dikonfirmasi. Silakan cek email Anda.';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
    } catch (e) {
      print('❌ SignIn error: $e');
      String errorMsg = e.toString();
      
      // Parse error untuk user-friendly message
      if (errorMsg.contains('Failed to fetch')) {
        errorMsg = 'Koneksi ke server gagal. Periksa koneksi internet Anda.';
      } else if (errorMsg.contains('Network')) {
        errorMsg = 'Masalah jaringan. Coba lagi.';
      } else if (errorMsg.contains('timeout')) {
        errorMsg = 'Koneksi timeout. Coba lagi.';
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
      print('   User: ${response.user?.id}');
      print('   Session: ${response.session != null}');

      if (response.user != null) {
        // Insert ke users table
        await client.from('users').insert({
          'id': response.user!.id,
          'name': name,
          'phone_number': phone,
          'role': 'user',
        });

        // Jika ada session (email confirmation disabled), langsung sign in
        if (response.session != null) {
          await _loadUserData(response.user!.id);
          state = state.copyWith(
            session: response.session,
            user: response.user,
            isLoading: false,
            errorMessage: null,
          );
          print('✅ SignUp completed and auto-signed in');
        } else {
          // Email confirmation required
          state = state.copyWith(
            isLoading: false,
            errorMessage: null,
          );
          print('✅ SignUp completed, email confirmation required');
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Registrasi gagal',
        );
      }
    } on AuthException catch (e) {
      print('❌ SignUp AuthException: ${e.message}');
      String errorMsg = e.message;
      
      // Parse error untuk user-friendly message
      if (errorMsg.contains('User already registered')) {
        errorMsg = 'Email sudah terdaftar. Silakan login.';
      } else if (errorMsg.contains('Password')) {
        errorMsg = 'Password tidak valid. Minimal 6 karakter.';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
    } catch (e) {
      print('❌ SignUp error: $e');
      String errorMsg = e.toString();
      
      // Parse error untuk user-friendly message
      if (errorMsg.contains('duplicate key') || errorMsg.contains('already exists')) {
        errorMsg = 'Email sudah terdaftar. Silakan login.';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);
      await client.auth.signOut();
      // State akan diupdate oleh auth state listener
      // Tapi kita juga set manual untuk memastikan
      state = AuthState(isLoading: false);
    } catch (e) {
      print('❌ SignOut error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal keluar: ${e.toString()}',
      );
    }
  }
}