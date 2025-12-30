// Example: How to integrate this backend with your Flutter app
// Add this to: lib/core/services/backend_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendApiService {
  static const String baseUrl = 'http://localhost:8000';
  String? _accessToken;

  // ============================================
  // Authentication
  // ============================================

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'display_name': displayName,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        // Save token to secure storage
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        // Save token to secure storage
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

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

  Future<bool> saveTranslation({
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      final response = await http.post(
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
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Save translation error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTranslations({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/translations?skip=$skip&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

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

  Future<Map<String, dynamic>?> getTranslationStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/translations/stats'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get stats error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeeklySummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/translations/weekly-summary'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get weekly summary error: $e');
      return null;
    }
  }

  // ============================================
  // Vocabulary
  // ============================================

  Future<List<Map<String, dynamic>>> getVocabulary({
    int skip = 0,
    int limit = 50,
    bool masteredOnly = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/vocabulary?skip=$skip&limit=$limit&mastered_only=$masteredOnly'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

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

  Future<bool> markVocabularyAsMastered(int vocabularyId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vocabulary/$vocabularyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'is_mastered': true,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Mark mastered error: $e');
      return false;
    }
  }

  // ============================================
  // Token Management
  // ============================================

  void setToken(String token) {
    _accessToken = token;
  }

  String? getToken() {
    return _accessToken;
  }

  void clearToken() {
    _accessToken = null;
  }

  bool get isAuthenticated => _accessToken != null;
}

// ============================================
// Usage Example in Provider
// ============================================

/*
class BackendProvider extends ChangeNotifier {
  final BackendApiService _api = BackendApiService();
  bool _isLoggedIn = false;
  Map<String, dynamic>? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    final success = await _api.login(email: email, password: password);
    if (success) {
      _isLoggedIn = true;
      _currentUser = await _api.getCurrentUser();
      notifyListeners();
    }
    return success;
  }

  Future<void> syncTranslation(Translation translation) async {
    await _api.saveTranslation(
      sourceText: translation.sourceText,
      translatedText: translation.targetText,
      sourceLang: translation.direction == 'ko_en' ? 'ko' : 'en',
      targetLang: translation.direction == 'ko_en' ? 'en' : 'ko',
    );
  }

  Future<Map<String, dynamic>?> fetchWeeklySummary() async {
    return await _api.getWeeklySummary();
  }
}
*/

