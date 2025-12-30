import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/main/screens/main_navigation_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/vocabulary/screens/weekly_summary_screen.dart';
import '../../features/vocabulary/screens/vocabulary_summary_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/notifications/notification_summary_screen.dart';
import '../constants/app_constants.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.splashRoute,
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoggingIn = state.uri.toString() == AppConstants.loginRoute;
      final isSplash = state.uri.toString() == AppConstants.splashRoute;

      if (!isLoggedIn && !isLoggingIn && !isSplash) {
        return AppConstants.loginRoute;
      }

      if (isLoggedIn && (isLoggingIn || isSplash)) {
        return AppConstants.homeRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: AppConstants.historyRoute,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppConstants.weeklySummaryRoute,
        name: 'weekly-summary',
        builder: (context, state) => const WeeklySummaryScreen(),
      ),
      GoRoute(
        path: AppConstants.vocabularyRoute,
        name: 'vocabulary',
        builder: (context, state) => const VocabularySummaryScreen(),
      ),
      GoRoute(
        path: AppConstants.settingsRoute,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppConstants.notificationSummaryRoute,
        name: 'notification-summary',
        builder: (context, state) {
          final notificationType =
              state.uri.queryParameters['type'] ?? 'weekly';
          return NotificationSummaryScreen(notificationType: notificationType);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}
