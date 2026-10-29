import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/bookings/presentation/departure_code_screen.dart';
import '../features/bookings/presentation/my_bookings_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/reports/presentation/admin_reports_screen.dart';
import '../features/reports/presentation/report_screen.dart';
import '../features/rides/presentation/edit_ride_screen.dart';
import '../features/rides/presentation/my_rides_screen.dart';
import '../features/rides/presentation/publish_ride_screen.dart';
import '../features/rides/presentation/ride_details_screen.dart';
import '../features/rides/presentation/ride_search_screen.dart';
import '../features/shell/presentation/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.value != null;
      final isSplash = state.uri.path == '/splash';
      final isAuthRoute =
          state.uri.path == '/login' ||
          state.uri.path == '/register' ||
          state.uri.path == '/forgot-password';

      if (isLoading || isSplash) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main Navigation Shell (Bottom Navigation Bar)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const RideSearchScreen(),
          ),
          GoRoute(
            path: '/publish',
            builder: (context, state) => const PublishRideScreen(),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const MyBookingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Other routes outside shell (pushed on top)
      GoRoute(
        path: '/rides/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final rideId = state.pathParameters['id']!;
          return RideDetailsScreen(rideId: rideId);
        },
      ),
      GoRoute(
        path: '/edit-ride/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final rideId = state.pathParameters['id']!;
          return EditRideScreen(rideId: rideId);
        },
      ),
      GoRoute(
        path: '/my-rides',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyRidesScreen(),
      ),
      GoRoute(
        path: '/departure-code/:bookingId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return DepartureCodeScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/report',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userId = state.uri.queryParameters['reportedUserId'];
          final rideId = state.uri.queryParameters['reportedRideId'];
          return ReportScreen(reportedUserId: userId, reportedRideId: rideId);
        },
      ),
      GoRoute(
        path: '/admin-reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminReportsScreen(),
      ),
    ],
  );
});
