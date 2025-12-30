import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/translation.dart';
import 'backend_api_service.dart';

class TranslationService {
  Future<Translation> translate({
    required String text,
    required TranslationDirection direction,
  }) async {
    final sourceLang = direction == TranslationDirection.koToEn ? 'ko' : 'en';
    final targetLang = direction == TranslationDirection.koToEn ? 'en' : 'ko';

    // 1. Try Backend Proxy (Preferred for Web and Secure Key handling)
    // Only works if user is authenticated with backend
    if (kIsWeb || BackendApiService().isAuthenticated) {
      final proxyResult = await BackendApiService().translateProxy(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      if (proxyResult != null) {
        return Translation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sourceText: text,
          targetText: proxyResult['translatedText'],
          direction: direction,
          createdAt: DateTime.now(),
        );
      }
    }

    // 2. Direct Papago Call (Native only, requires keys in AppConstants)
    if (!kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse(AppConstants.papagoApiUrl),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-Naver-Client-Id': AppConstants.papagoClientId,
            'X-Naver-Client-Secret': AppConstants.papagoClientSecret,
          },
          body: {'source': sourceLang, 'target': targetLang, 'text': text},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final translatedText =
              data['message']['result']['translatedText'] as String;

          return Translation(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sourceText: text,
            targetText: translatedText,
            direction: direction,
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        print('Direct translation error: $e');
        // Fall through to mock
      }
    }

    // 3. Fallback to Mock (for Web demo or when keys/backend missing)
    return _mockTranslate(text, direction);
  }

  Translation _mockTranslate(String text, TranslationDirection direction) {
    // Simple mock translation for web demo / testing
    final mockTranslations = <String, String>{
      // Korean to English
      '안녕하세요': 'Hello',
      '감사합니다': 'Thank you',
      '좋은 아침입니다': 'Good morning',
      '사랑해': 'I love you',
      // English to Korean
      'Hello': '안녕하세요',
      'Thank you': '감사합니다',
      'Good morning': '좋은 아침입니다',
      'I love you': '사랑해',
    };

    final translatedText = mockTranslations[text] ?? '[Mock Translation] $text';

    return Translation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceText: text,
      targetText: translatedText,
      direction: direction,
      createdAt: DateTime.now(),
    );
  }

  Future<String> detectLanguage(String text) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.papagoDetectUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'X-Naver-Client-Id': AppConstants.papagoClientId,
          'X-Naver-Client-Secret': AppConstants.papagoClientSecret,
        },
        body: {'query': text},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['langCode'] as String;
      } else {
        return 'ko'; // Default to Korean
      }
    } catch (e) {
      return 'ko'; // Default to Korean on error
    }
  }
}
