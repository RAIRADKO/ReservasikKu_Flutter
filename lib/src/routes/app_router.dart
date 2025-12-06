import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/home/views/home_screen.dart';
import '../features/reservation/views/create_reservation_screen.dart';
import '../features/reservation/views/reservation_detail_screen.dart';
import '../features/reservation/views/reservation_history_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/admin/views/admin_dashboard_screen.dart';
import '../features/admin/views/manage_reservations_screen.dart';
import '../features/admin/views/manage_tables_screen.dart';
// PERBAIKAN: Import yang benar
import '../features/auth/controllers/auth_controller.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-reservation',
        builder: (context, state) => const CreateReservationScreen(),
      ),
      GoRoute(
        path: '/reservations',
        builder: (context, state) => const ReservationHistoryScreen(),
      ),
      GoRoute(
        path: '/reservations/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReservationDetailScreen(reservationId: int.parse(id));
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/reservations',
        builder: (context, state) => const ManageReservationsScreen(),
      ),
      GoRoute(
        path: '/admin/tables',
        builder: (context, state) => const ManageTablesScreen(),
      ),
    ],
    redirect: (context, state) {
      // Jika masih loading, jangan redirect
      if (authState.isLoading) {
        return null;
      }
      
      final isAuth = authState.session != null;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';
      final isAdminRoute = state.uri.path.startsWith('/admin');
      final isUserRoute = !isAdminRoute && !isLoggingIn;
      
      // Jika tidak login dan mencoba akses route yang memerlukan auth
      if (!isAuth && isUserRoute) {
        return '/login';
      }
      
      // Jika tidak login dan mencoba akses admin route
      if (!isAuth && isAdminRoute) {
        return '/login';
      }
      
      // Jika sudah login dan berada di halaman login/register
      if (isAuth && isLoggingIn) {
        // Redirect berdasarkan role
        if (authState.role == 'admin') {
          return '/admin/dashboard';
        }
        return '/home';
      }
      
      // Jika user biasa mencoba akses admin route
      if (isAuth && isAdminRoute && authState.role != 'admin') {
        return '/home';
      }
      
      // Jika admin mencoba akses user route
      if (isAuth && isUserRoute && authState.role == 'admin') {
        return '/admin/dashboard';
      }
      
      return null;
    },
  );
});