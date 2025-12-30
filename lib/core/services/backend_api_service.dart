import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/translation.dart';

/// Backend API Service for communicating with the FastAPI backend
///
/// This service handles:
/// - User authentication (register, login)
/// - Translation storage and retrieval
/// - Weekly vocabulary summaries
/// - Vocabulary management
class BackendApiService {
  static final BackendApiService _instance = BackendApiService._internal();
  
  factory BackendApiService() {
    return _instance;
  }
  
  BackendApiService._internal();

  static const String baseUrl = 'http://localhost:8000';
  static const String _tokenKey = 'backend_access_token';
  final _storage = const FlutterSecureStorage();

  String? _accessToken;

  /// Initialize the service and load stored token
  Future<void> init() async {
    _accessToken = await _storage.read(key: _tokenKey);
  }

  // ============================================
  // Authentication
  // ============================================

  /// Register a new user account
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
              if (displayName != null) 'display_name': displayName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveToken(data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveToken(data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Get current authenticated user info
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!isAuthenticated) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  // ============================================
  // Translations
  // ============================================

  /// Save a translation to the backend
  Future<bool> saveTranslation({
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (!isAuthenticated) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/translations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_accessToken',
            },
            body: json.encode({
              'source_text': sourceText,
              'translated_text': translatedText,
              'source_lang': sourceLang,
              'target_lang': targetLang,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      print('Save translation error: $e');
      return false;
    }
  }

  /// Proxy translation request to backend
  Future<Map<String, dynamic>?> translateProxy({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    // Ideally we should allow unauthenticated translations if the backend permits,
    // but our backend endpoint uses Depends(get_current_user).
    if (!isAuthenticated) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/translations/proxy'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_accessToken',
            },
            body: json.encode({
              'text': text,
              'source_lang': sourceLang,
              'target_lang': targetLang,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      print('Proxy translation failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Proxy translation error: $e');
      return null;
    }
  }

  /// Save a translation to the backend
  Future<bool> syncTranslation(Translation translation) async {
    return await saveTranslation(
      sourceText: translation.sourceText,
      translatedText: translation.targetText,
      sourceLang: translation.sourceLanguage,
      targetLang: translation.targetLanguage,
    );
  }

  /// Get translation history
  Future<List<Map<String, dynamic>>> getTranslations({
    int skip = 0,
    int limit = 20,
  }) async {
    if (!isAuthenticated) return [];

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/translations?skip=$skip&limit=$limit'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get translations error: $e');
      return [];
    }
  }

  /// Get translation statistics
  Future<Map<String, dynamic>?> getTranslationStats() async {
    if (!isAuthenticated) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/translations/stats'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get stats error: $e');
      return null;
    }
  }

  /// Get weekly vocabulary summary with most frequent words
  Future<Map<String, dynamic>?> getWeeklySummary() async {
    if (!isAuthenticated) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/translations/weekly-summary'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get weekly summary error: $e');
      return null;
    }
  }

  /// Get daily vocabulary summary (last 24 hours)
  Future<Map<String, dynamic>?> getDailySummary() async {
    if (!isAuthenticated) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/translations/daily-summary'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get daily summary error: $e');
      return null;
    }
  }

  /// Get two-day vocabulary summary (last 48 hours)
  Future<Map<String, dynamic>?> getTwoDaySummary() async {
    if (!isAuthenticated) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/translations/two-day-summary'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get two-day summary error: $e');
      return null;
    }
  }

  /// Delete a translation
  Future<bool> deleteTranslation(String translationId) async {
    if (!isAuthenticated) return false;

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/translations/$translationId'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Delete translation error: $e');
      return false;
    }
  }

  // ============================================
  // Vocabulary
  // ============================================

  /// Get vocabulary items
  Future<List<Map<String, dynamic>>> getVocabulary({
    int skip = 0,
    int limit = 50,
    bool masteredOnly = false,
  }) async {
    if (!isAuthenticated) return [];

    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/vocabulary?skip=$skip&limit=$limit&mastered_only=$masteredOnly',
            ),
            headers: {'Authorization': 'Bearer $_accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get vocabulary error: $e');
      return [];
    }
  }

  /// Mark a vocabulary item as mastered
  Future<bool> markVocabularyAsMastered(String vocabularyId) async {
    if (!isAuthenticated) return false;

    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/vocabulary/$vocabularyId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_accessToken',
            },
            body: json.encode({'is_mastered': true}),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Mark mastered error: $e');
      return false;
    }
  }

  /// Delete a vocabulary item
  Future<bool> deleteVocabulary(String vocabularyId) async {
    if (!isAuthenticated) return false;

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/vocabulary/$vocabularyId'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Delete vocabulary error: $e');
      return false;
    }
  }

  // ============================================
  // Token Management
  // ============================================

  Future<void> _saveToken(String token) async {
    _accessToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Set token manually (useful for testing or external auth)
  Future<void> setToken(String token) async {
    await _saveToken(token);
  }

  /// Get current token
  String? getToken() {
    return _accessToken;
  }

  /// Clear token and logout
  Future<void> clearToken() async {
    _accessToken = null;
    await _storage.delete(key: _tokenKey);
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  // ============================================
  // Health Check
  // ============================================

  /// Check if backend API is reachable
  Future<bool> isBackendHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }

  /// Update FCM token for push notifications
  Future<bool> updateFcmToken(String token) async {
    if (!isAuthenticated) return false;

    try {
      // Note: This endpoint might not exist in the backend yet, 
      // but we add the method to satisfy the frontend call.
      // If the backend doesn't support it, it will return 404 but not crash the app.
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_accessToken',
            },
            body: json.encode({'fcm_token': token}),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Update FCM token error: $e');
      return false;
    }
  }

  /// Update notification preferences
  Future<bool> updateNotificationPreferences({
    required String frequency,
    required String preferredTime,
  }) async {
    if (!isAuthenticated) return false;

    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/users/preferences'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_accessToken',
            },
            body: json.encode({
              'notification_frequency': frequency,
              'preferred_time': preferredTime,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Update preferences error: $e');
      return false;
    }
  }
}
