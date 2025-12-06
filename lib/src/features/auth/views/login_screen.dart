import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/utils.dart';
import '../../../common/app_theme.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    print('🔑 Login attempt');
    print('   Email: $email');
    
    try {
      // Clear previous error
      ref.read(authProvider.notifier).clearError();
      
      // Panggil signIn
      await ref.read(authProvider.notifier).signIn(email, password);
      
      // Cek apakah widget masih ada sebelum melanjutkan
      if (!mounted) return;
      
      // Tunggu sebentar untuk state update
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!mounted) return;
      
      // Cek error
      final authState = ref.read(authProvider);
      
      if (authState.errorMessage != null) {
        print('❌ Login failed: ${authState.errorMessage}');
        showToast(context, _parseErrorMessage(authState.errorMessage!), error: true);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      } else if (authState.session != null && !authState.isLoading) {
        print('✅ Login successful');
        // Router akan handle redirect otomatis
        // Loading akan dihentikan oleh listener
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (mounted) {
        showToast(context, _parseErrorMessage(e.toString()), error: true);
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseErrorMessage(String error) {
    // Parse error messages untuk user-friendly
    if (error.contains('Invalid login credentials')) {
      return 'Email atau password salah';
    } else if (error.contains('Failed to fetch') || error.contains('Network')) {
      return 'Koneksi gagal. Periksa internet Anda';
    } else if (error.contains('timeout')) {
      return 'Koneksi timeout. Coba lagi';
    }
    return 'Login gagal. Silakan coba lagi';
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes dengan pengecekan mounted
    ref.listen(authProvider, (previous, next) {
      if (!mounted) return;
      
      print('👂 Auth state listener:');
      print('   Previous session: ${previous?.session != null}');
      print('   Next session: ${next.session != null}');
      print('   Loading: ${next.isLoading}');
      print('   Error: ${next.errorMessage}');
      
      // Jika login berhasil (session muncul dan tidak loading)
      if (next.session != null && !next.isLoading && previous?.session == null) {
        print('✅ Login successful detected');
        setState(() => _isLoading = false);
        // Router akan handle redirect otomatis
      }
      
      // Jika ada error atau loading selesai, stop loading
      if (next.errorMessage != null || (!next.isLoading && _isLoading)) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'RestoReserve',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reservasi Meja Restoran',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Form Card
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email, color: AppTheme.primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
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
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : () {
                                showToast(context, 'Fitur lupa password belum tersedia');
                              },
                              child: const Text('Lupa password?'),
                            ),
                          ),
                          const SizedBox(height: 28),
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
                              onPressed: (_isLoading || authState.isLoading) ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: (_isLoading || authState.isLoading)
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : () => context.push('/register'),
                                child: const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Test credentials helper
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: AppTheme.lightGradient,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Akun Test:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Admin: admin@resto.com / admin123',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'User: user@resto.com / user123',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}