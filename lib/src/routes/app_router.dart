import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
import '../providers/auth_provider.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: ref.watch(authProvider),
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
      final authState = ref.read(authProvider);
      
      if (authState.isLoading) return null;
      
      final isAuth = authState.session != null;
      final isLoggingIn = state.location == '/login' || state.location == '/register';
      
      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/home';
      
      // Redirect admin ke dashboard admin
      if (isAuth && authState.role == 'admin') {
        if (state.location == '/home' || state.location == '/reservations' || state.location == '/profile') {
          return '/admin/dashboard';
        }
      }
      
      return null;
    },
  );
}