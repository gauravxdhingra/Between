import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/groups/presentation/join_group_screen.dart';
import '../../shared/providers/auth_provider.dart';
import 'deep_link_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.onDispose(refreshNotifier.dispose);
  ref.listen(authStateProvider, (_, _) => refreshNotifier.value++);
  ref.listen(localTestModeProvider, (_, _) => refreshNotifier.value++);
  ref.listen(pendingJoinProvider, (_, _) => refreshNotifier.value++);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/landing', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/app', builder: (_, _) => const DashboardScreen()),
      GoRoute(
        path: '/join/:groupId',
        builder: (_, state) {
          final groupId = state.pathParameters['groupId']!;
          final token = state.uri.queryParameters['token'] ?? '';
          return JoinGroupScreen(groupId: groupId, token: token);
        },
      ),
    ],
    redirect: (context, state) {
      final authSnapshot = ref.read(authStateProvider);
      final localTestMode = ref.read(localTestModeProvider);
      final pendingJoin = ref.read(pendingJoinProvider);
      final location = state.uri.path;

      if (localTestMode) {
        // Still honour pending join links in test mode
        if (pendingJoin != null) {
          final parsed = DeepLinkService.parseJoin(pendingJoin);
          if (parsed != null) {
            ref.read(pendingJoinProvider.notifier).state = null;
            return '/join/${parsed.groupId}?token=${parsed.token}';
          }
        }
        return location == '/app' ? null : '/app';
      }

      return authSnapshot.when(
        loading: () => location == '/splash' ? null : '/splash',
        error: (_, _) => '/landing',
        data: (auth) {
          if (!auth.isSupabaseConfigured) {
            return location == '/landing' ? null : '/landing';
          }

          if (!auth.isAuthenticated) {
            // If a join link is waiting, go to landing — after auth the
            // redirect will pick it up again.
            return location == '/landing' ? null : '/landing';
          }

          if (!auth.hasProfile) {
            return location == '/onboarding' ? null : '/onboarding';
          }

          // Authenticated + profile: consume any pending join link first.
          if (pendingJoin != null) {
            final parsed = DeepLinkService.parseJoin(pendingJoin);
            if (parsed != null) {
              ref.read(pendingJoinProvider.notifier).state = null;
              return '/join/${parsed.groupId}?token=${parsed.token}';
            }
          }

          return location == '/app' ? null : '/app';
        },
      );
    },
    refreshListenable: refreshNotifier,
  );
});
