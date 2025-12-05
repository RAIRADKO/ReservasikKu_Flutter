import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/utils.dart';
// PERBAIKAN: Import controller yang benar
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
// ... (sisa kode sama seperti sebelumnya) {
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
    
    print('🔑 Login button pressed');
    print('   Email: $email');
    
    try {
      // Clear previous error
      ref.read(authProvider.notifier).clearError();
      
      // Panggil signIn
      await ref.read(authProvider.notifier).signIn(email, password);
      
      // Tunggu sebentar untuk memastikan state terupdate
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Cek apakah ada error
      final authState = ref.read(authProvider);
      
      if (mounted) {
        if (authState.errorMessage != null) {
          showToast(context, authState.errorMessage!, error: true);
          setState(() => _isLoading = false);
        } else if (authState.session != null) {
          // Login berhasil, router akan otomatis redirect
          print('✅ Login successful, router will redirect');
          // Keep loading true, let router handle navigation
        }
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (mounted) {
        showToast(context, 'Error: $e', error: true);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen(authProvider, (previous, next) {
      print('👂 Auth state listener:');
      print('   Previous session: ${previous?.session != null}');
      print('   Next session: ${next.session != null}');
      print('   Loading: ${next.isLoading}');
      print('   Error: ${next.errorMessage}');
      
      // Jika login berhasil (ada session dan tidak loading)
      if (next.session != null && !next.isLoading && previous?.session == null) {
        print('✅ Login successful detected in listener');
        // Router akan handle redirect
      }
      
      // Jika ada error, stop loading
      if (next.errorMessage != null && mounted) {
        setState(() => _isLoading = false);
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
                            // TODO: Implement forgot password
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
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading ? null : () => context.push('/register'),
                        child: const Text('Belum punya akun? Daftar'),
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