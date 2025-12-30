import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation.dart';
import 'storage_service.dart';

class BackgroundSyncService {
  static const String _tokenKey = 'backend_token';
  static const String _baseUrl = 'http://localhost:8000';

  // Get stored auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get auth headers
  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await _getToken();
    if (token == null) return null;

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Sync a single translation
  Future<bool> syncTranslation(Translation translation) async {
    final headers = await _getAuthHeaders();
    if (headers == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/translations'),
        headers: headers,
        body: json.encode({
          'source_text': translation.sourceText,
          'translated_text': translation.targetText,
          'source_lang': translation.sourceLanguage,
          'target_lang': translation.targetLanguage,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Background sync translation error: $e');
      return false;
    }
  }

  // Sync all pending translations
  Future<int> syncAllPendingTranslations() async {
    final headers = await _getAuthHeaders();
    if (headers == null) {
      print('No auth token available for background sync');
      return 0;
    }

    try {
      // Get all translations from storage
      final storageService = StorageService();
      final allTranslations = await storageService.getTranslations();

      if (allTranslations.isEmpty) {
        return 0;
      }

      int syncedCount = 0;

      // Sync each translation (in a real app, you'd batch this)
      for (final translation in allTranslations) {
        // Only sync translations that haven't been synced yet
        // In a real implementation, you'd track sync status
        final success = await syncTranslation(translation);
        if (success) {
          syncedCount++;
        }
      }

      print('Background sync completed: $syncedCount translations synced');
      return syncedCount;
    } catch (e) {
      print('Background sync error: $e');
      return 0;
    }
  }

  // Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }
}
