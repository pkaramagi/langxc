import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/backend_api_service.dart';

enum NotificationFrequency { daily, twoDay, weekly }

extension NotificationFrequencyExtension on NotificationFrequency {
  String get value {
    switch (this) {
      case NotificationFrequency.daily:
        return 'daily';
      case NotificationFrequency.twoDay:
        return 'two_day';
      case NotificationFrequency.weekly:
        return 'weekly';
    }
  }

  static NotificationFrequency fromString(String value) {
    switch (value) {
      case 'daily':
        return NotificationFrequency.daily;
      case 'two_day':
        return NotificationFrequency.twoDay;
      case 'weekly':
        return NotificationFrequency.weekly;
      default:
        return NotificationFrequency.weekly; // default
    }
  }

  String get displayName {
    switch (this) {
      case NotificationFrequency.daily:
        return 'Daily';
      case NotificationFrequency.twoDay:
        return 'Every 2 Days';
      case NotificationFrequency.weekly:
        return 'Weekly';
    }
  }
}

class UserPreferences {
  final NotificationFrequency frequency;
  final String preferredTime; // Format: "HH:MM"
  final DateTime? lastNotificationSent;

  const UserPreferences({
    required this.frequency,
    required this.preferredTime,
    this.lastNotificationSent,
  });

  // Default preferences
  factory UserPreferences.defaultPrefs() {
    return const UserPreferences(
      frequency: NotificationFrequency.weekly,
      preferredTime: '09:00', // 9 AM
      lastNotificationSent: null,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.value,
      'preferredTime': preferredTime,
      'lastNotificationSent': lastNotificationSent?.toIso8601String(),
    };
  }

  // Create from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      frequency: NotificationFrequencyExtension.fromString(
        json['frequency'] ?? 'weekly',
      ),
      preferredTime: json['preferredTime'] ?? '09:00',
      lastNotificationSent: json['lastNotificationSent'] != null
          ? DateTime.parse(json['lastNotificationSent'])
          : null,
    );
  }

  // Check if user should receive notification now
  bool shouldReceiveNotification() {
    if (lastNotificationSent == null) return true;

    final now = DateTime.now();
    final timeDifference = now.difference(lastNotificationSent!);

    switch (frequency) {
      case NotificationFrequency.daily:
        return timeDifference.inHours >= 24;
      case NotificationFrequency.twoDay:
        return timeDifference.inHours >= 48;
      case NotificationFrequency.weekly:
        return timeDifference.inDays >= 7;
    }
  }
}

class UserPreferencesService {
  static const String _preferencesKey = 'user_notification_preferences';

  final BackendApiService _backendService = BackendApiService();

  // Get user preferences
  Future<UserPreferences> getPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);

      if (preferencesJson != null) {
        final json = jsonDecode(preferencesJson) as Map<String, dynamic>;
        return UserPreferences.fromJson(json);
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }

    // Return default preferences if loading fails
    return UserPreferences.defaultPrefs();
  }

  // Save user preferences locally and sync to backend
  Future<void> savePreferences(UserPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferencesKey, jsonEncode(preferences.toJson()));

      // Sync to backend if user is authenticated
      final success = await _backendService.updateNotificationPreferences(
        frequency: preferences.frequency.value,
        preferredTime: preferences.preferredTime,
      );

      if (!success) {
        print('Failed to sync preferences to backend');
      }
    } catch (e) {
      print('Error saving preferences: $e');
      rethrow;
    }
  }

  // Update last notification sent time
  Future<void> updateLastNotificationSent(DateTime sentTime) async {
    try {
      final currentPrefs = await getPreferences();
      final updatedPrefs = UserPreferences(
        frequency: currentPrefs.frequency,
        preferredTime: currentPrefs.preferredTime,
        lastNotificationSent: sentTime,
      );
      await savePreferences(updatedPrefs);
    } catch (e) {
      print('Error updating last notification time: $e');
    }
  }

  // Reset preferences to defaults
  Future<void> resetToDefaults() async {
    await savePreferences(UserPreferences.defaultPrefs());
  }

  // Get notification schedule info
  Future<Map<String, dynamic>> getNotificationScheduleInfo() async {
    final prefs = await getPreferences();
    final shouldSend = prefs.shouldReceiveNotification();

    final nextNotificationTime = _calculateNextNotificationTime(prefs);

    return {
      'frequency': prefs.frequency.displayName,
      'preferredTime': prefs.preferredTime,
      'lastNotificationSent': prefs.lastNotificationSent?.toIso8601String(),
      'shouldReceiveNotification': shouldSend,
      'nextNotificationTime': nextNotificationTime?.toIso8601String(),
    };
  }

  DateTime? _calculateNextNotificationTime(UserPreferences prefs) {
    if (prefs.lastNotificationSent == null) return null;

    final lastSent = prefs.lastNotificationSent!;
    final preferredTime = prefs.preferredTime;

    // Parse preferred time
    final timeParts = preferredTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    DateTime nextTime;
    switch (prefs.frequency) {
      case NotificationFrequency.daily:
        nextTime = lastSent.add(const Duration(days: 1));
        break;
      case NotificationFrequency.twoDay:
        nextTime = lastSent.add(const Duration(days: 2));
        break;
      case NotificationFrequency.weekly:
        nextTime = lastSent.add(const Duration(days: 7));
        break;
    }

    // Set the preferred time
    nextTime = DateTime(
      nextTime.year,
      nextTime.month,
      nextTime.day,
      hour,
      minute,
    );

    return nextTime;
  }
}
