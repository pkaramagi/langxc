import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';

class PapagoService {
  static const Duration _timeout = Duration(seconds: 10);

  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (text.trim().isEmpty) {
      return '';
    }

    try {
      final backendService = BackendApiService();
      final result = await backendService.translateProxy(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      if (result != null && result.containsKey('translatedText')) {
        return result['translatedText'] as String;
      }

      // Fallback to mock for development if proxy fails/unauthenticated
      return _mockTranslate(text, sourceLang, targetLang);
    } catch (e) {
      return _mockTranslate(text, sourceLang, targetLang);
    }
  }

  String _mockTranslate(String text, String sourceLang, String targetLang) {
    final mockTranslations = <String, String>{
      // Korean to English
      '안녕하세요': 'Hello',
      '감사합니다': 'Thank you',
      '좋은 아침입니다': 'Good morning',
      '좋은 밤입니다': 'Good night',
      '사랑해': 'I love you',
      '어떻게 지내세요?': 'How are you?',
      '만나서 반갑습니다': 'Nice to meet you',
      '다시 만나요': 'See you again',
      // English to Korean
      'Hello': '안녕하세요',
      'Thank you': '감사합니다',
      'Good morning': '좋은 아침입니다',
      'Good night': '좋은 밤입니다',
      'I love you': '사랑해',
      'How are you?': '어떻게 지내세요?',
      'Nice to meet you': '만나서 반갑습니다',
      'See you again': '다시 만나요',
    };

    return mockTranslations[text] ?? '[Mock] $text';
  }
}
