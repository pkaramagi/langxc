import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_sync_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/translation_provider.dart';
import 'core/providers/history_provider.dart';
import 'features/translation/providers/translation_provider.dart' as modern;
import 'core/routing/app_router.dart';
// import 'firebase_options.dart';

// Background message handler
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   print("Handling a background message: ${message.messageId}");
// }

// WorkManager callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case 'syncTranslations':
          // Initialize storage service
          await StorageService.init();

          // Perform background sync
          final syncService = BackgroundSyncService();
          final syncedCount = await syncService.syncAllPendingTranslations();

          if (kDebugMode) {
            print('Background sync completed: $syncedCount translations synced');
          }
          return true;
        default:
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Background task failed: $e');
      }
      return false;
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up background message handler
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize storage
  await StorageService.init();

  // Initialize WorkManager (only on mobile platforms, not web)
  // WorkManager doesn't support web platform - skip it entirely on web
  if (kIsWeb) {
    if (kDebugMode) {
      print('Running on web platform - WorkManager disabled');
    }
  } else {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true, // Set to false in production
      );

      // Register background sync task (runs every hour)
      await Workmanager().registerPeriodicTask(
        'syncTranslations',
        'syncPendingTranslations',
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected, // Only run when connected
        ),
      );
      if (kDebugMode) {
        print('WorkManager initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WorkManager initialization failed: $e');
      }
      // Continue app startup even if WorkManager fails
    }
  }

  // Initialize notifications
  final notificationService = NotificationService();
  notificationService.navigateTo =
      (String routeName, Map<String, String> queryParams) {
        // Build the full route with query parameters
        final uri = Uri(path: routeName, queryParameters: queryParams);
        AppRouter.router.go(uri.toString());
      };
  await notificationService.initialize();

  runApp(const LangXCApp());
}

class LangXCApp extends StatelessWidget {
  const LangXCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = modern.TranslationProvider();
            provider.init(); // Initialize backend service
            return provider;
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'LangXC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
