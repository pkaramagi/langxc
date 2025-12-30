// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../services/backend_api_service.dart';
import '../services/auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final BackendApiService _backendService = BackendApiService();
  final AuthService _authService = AuthService();

  String? _fcmToken;

  // Navigation callback to be set by the app
  void Function(String routeName, Map<String, String> queryParams)? navigateTo;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Firebase disabled for now
    if (kDebugMode) {
      print('NotificationService initialized (Firebase disabled)');
    }

    /*
    // Request permission for notifications
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');

      // Send token to backend if user is authenticated
      if (_authService.currentUser != null && _fcmToken != null) {
        await _sendTokenToBackend();
      }
    } else {
      print('User declined or has not accepted permission');
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('FCM Token refreshed: $newToken');

      // Send updated token to backend
      if (_authService.currentUser != null) {
        _sendTokenToBackend();
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _handleNotification(message);
      }
    });

    // Handle background messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      _handleNotificationTap(message);
    });

    // Handle messages when app is launched from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
    */
  }

  // Method kept for when Firebase is re-enabled
  // ignore: unused_element
  Future<void> _sendTokenToBackend() async {
    if (_fcmToken != null && _authService.currentUser != null) {
      try {
        await _backendService.updateFcmToken(_fcmToken!);
        if (kDebugMode) {
          print('FCM token sent to backend successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to send FCM token to backend: $e');
        }
      }
    }
  }

  /*
  void _handleNotification(RemoteMessage message) {
    // Handle foreground notification
    // You can show a local notification or update UI
    print('Handling notification: ${message.notification?.title}');

    // For now, we'll just print the details
    // In a real app, you'd show a local notification or update the UI
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle when user taps on notification
    print('User tapped notification: ${message.notification?.title}');

    // Navigate to appropriate screen based on notification type
    final data = message.data;
    if (data.containsKey('type')) {
      final type = data['type'];
      switch (type) {
        case 'daily_summary':
        case 'two_day_summary':
        case 'weekly_summary':
          // Navigate to summary screen
          _navigateToSummaryScreen(type, data);
          break;
        default:
          print('Unknown notification type: $type');
      }
    }
  }

  void _navigateToSummaryScreen(
    String notificationType,
    Map<String, dynamic> data,
  ) {
    if (navigateTo != null) {
      // Navigate to notification summary screen with query parameters
      navigateTo!('/notification-summary', {'type': notificationType});
    } else {
      print('Navigation callback not set for notification tap');
    }
  }
  */

  // Method to get notification settings (useful for settings screen)
  Future<dynamic> getNotificationSettings() async {
    // return await _firebaseMessaging.getNotificationSettings();
    return null;
  }

  // Method to manually refresh token
  Future<void> refreshToken() async {
    /*
    _fcmToken = await _firebaseMessaging.getToken();
    if (_fcmToken != null && _authService.currentUser != null) {
      await _sendTokenToBackend();
    }
    */
  }
}
