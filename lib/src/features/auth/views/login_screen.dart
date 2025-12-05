import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/utils.dart';
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
    
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    print('🔑 Login attempt');
    print('   Email: $email');
    
    try {
      // Clear previous error - pastikan widget masih mounted
      if (!mounted) return;
      ref.read(authProvider.notifier).clearError();
      
      // Panggil signIn
      await ref.read(authProvider.notifier).signIn(email, password);
      
      // Cek apakah widget masih ada sebelum melanjutkan
      if (!mounted) return;
      
      // Tunggu sebentar untuk state update
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // Cek error
      final authState = ref.read(authProvider);
      
      if (authState.errorMessage != null) {
        print('❌ Login failed: ${authState.errorMessage}');
        showToast(context, _parseErrorMessage(authState.errorMessage!), error: true);
        setState(() => _isLoading = false);
      } else if (authState.session != null) {
        print('✅ Login successful');
        // Keep loading, router will handle redirect
      } else {
        // Tidak ada session dan tidak ada error - mungkin masih loading
        print('⏳ Still loading...');
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
      
      // Jika login berhasil
      if (next.session != null && !next.isLoading && previous?.session == null) {
        print('✅ Login successful detected');
        // Router akan handle redirect otomatis
      }
      
      // Jika ada error, stop loading
      if (next.errorMessage != null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'RestoReserve',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reservasi Meja Restoran',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : () {
                            showToast(context, 'Fitur lupa password belum tersedia');
                          },
                          child: const Text('Lupa password?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isLoading || authState.isLoading) ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            disabledBackgroundColor: Colors.blue.withOpacity(0.6),
                          ),
                          child: (_isLoading || authState.isLoading)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading ? null : () => context.push('/register'),
                        child: const Text('Belum punya akun? Daftar'),
                      ),
                      const SizedBox(height: 24),
                      // Test credentials helper
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Akun Test:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Admin: admin@resto.com / admin123',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              'User: user@resto.com / user123',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
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
    );
  }
}