import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/utils.dart';
import '../../../common/app_theme.dart';
// PERBAIKAN: Hapus import providers/auth_provider.dart, hanya gunakan ini:
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

@override
ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registerFormProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark, AppTheme.backgroundLight],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: const Icon(Icons.person, color: AppTheme.primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                onChanged: (value) => ref.read(registerFormProvider.notifier).state = 
                    formState.copyWith(name: value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email, color: AppTheme.primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => ref.read(registerFormProvider.notifier).state = 
                    formState.copyWith(email: value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email wajib diisi';
                  }
                  if (!value.contains('@')) {
                    return 'Email tidak valid';
                  }
                  return null;
                },
              ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                obscureText: true,
                onChanged: (value) => ref.read(registerFormProvider.notifier).state = 
                    formState.copyWith(password: value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password wajib diisi';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Nomor HP',
                              prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => ref.read(registerFormProvider.notifier).state = 
                    formState.copyWith(phone: value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor HP wajib diisi';
                  }
                  if (value.length < 10) {
                    return 'Nomor HP minimal 10 digit';
                  }
                  return null;
                },
              ),
                          const SizedBox(height: 32),
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: formState.isValid && !formState.isLoading && !authState.isLoading
                                  ? () async {
                                      if (_formKey.currentState!.validate()) {
                                        if (!mounted) return;
                                        
                                        ref.read(registerFormProvider.notifier).state = 
                                            formState.copyWith(isLoading: true);
                                        
                                        await ref.read(authProvider.notifier).signUp(
                                          name: formState.name.trim(),
                                          email: formState.email.trim(),
                                          password: formState.password.trim(),
                                          phone: formState.phone.trim(),
                                        );
                                        
                                        if (!mounted) return;
                                        
                                        // Tunggu sebentar untuk state update
                                        await Future.delayed(const Duration(milliseconds: 200));
                                        
                                        if (!mounted) return;
                                        
                                        final updatedAuthState = ref.read(authProvider);
                                        
                                        ref.read(registerFormProvider.notifier).state = 
                                            formState.copyWith(isLoading: false);
                                        
                                        if (updatedAuthState.errorMessage != null) {
                                          showToast(context, updatedAuthState.errorMessage!, error: true);
                                        } else if (updatedAuthState.session != null) {
                                          // Auto-login berhasil, router akan redirect
                                          showToast(context, 'Registrasi berhasil!');
                                        } else {
                                          // Email confirmation required
                                          showToast(context, 'Registrasi berhasil! Silakan cek email untuk konfirmasi.');
                                          context.pop();
                                        }
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: (formState.isLoading || authState.isLoading)
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Daftar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}