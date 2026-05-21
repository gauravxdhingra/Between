import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../shared/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.onDispose(refreshNotifier.dispose);
  ref.listen(authStateProvider, (_, _) {
    refreshNotifier.value++;
  });

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/landing', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/app', builder: (_, _) => const DashboardScreen()),
    ],
    redirect: (context, state) {
      final authSnapshot = ref.read(authStateProvider);
      final location = state.uri.path;

      return authSnapshot.when(
        loading: () => location == '/splash' ? null : '/splash',
        error: (_, _) => '/landing',
        data: (auth) {
          if (!auth.isSupabaseConfigured) {
            return location == '/landing' ? null : '/landing';
          }

          if (!auth.isAuthenticated) {
            return location == '/landing' ? null : '/landing';
          }

          if (!auth.hasProfile) {
            return location == '/onboarding' ? null : '/onboarding';
          }

          return location == '/app' ? null : '/app';
        },
      );
    },
    refreshListenable: refreshNotifier,
  );
});
