import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';

final loginFormProvider = StateProvider<LoginFormState>((ref) {
  return LoginFormState();
});

final registerFormProvider = StateProvider<RegisterFormState>((ref) {
  return RegisterFormState();
});

class LoginFormState {
  final String email;
  final String password;
  final bool isLoading;

  LoginFormState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isLoading,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isValid => email.isNotEmpty && password.isNotEmpty;
}

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

  bool get isValid => 
      name.isNotEmpty && 
      email.isNotEmpty && 
      password.isNotEmpty && password.length >= 6 &&
      phone.isNotEmpty && phone.length >= 10;
}