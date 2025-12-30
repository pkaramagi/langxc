import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/papago_service.dart';
import '../../../core/services/backend_api_service.dart';

class TranslationProvider with ChangeNotifier {
  final PapagoService _papagoService = PapagoService();
  final BackendApiService _backendService = BackendApiService();

  String _sourceText = '';
  String _translatedText = '';
  String _sourceLang = 'ko';
  String _targetLang = 'en';
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  /// Initialize the provider and backend service
  Future<void> init() async {
    await _backendService.init();
  }

  String get sourceText => _sourceText;
  String get translatedText => _translatedText;
  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get sourceLangName => _sourceLang == 'ko' ? '한국어' : 'English';
  String get targetLangName => _targetLang == 'ko' ? '한국어' : 'English';

  void setSourceText(String text) {
    _sourceText = text;
    _errorMessage = null;
    notifyListeners();

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (text.trim().isEmpty) {
      _translatedText = '';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Debounce translation
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performTranslation();
    });
  }

  void swapLanguages() {
    final tempLang = _sourceLang;
    _sourceLang = _targetLang;
    _targetLang = tempLang;

    final tempText = _sourceText;
    _sourceText = _translatedText;
    _translatedText = tempText;

    notifyListeners();

    // Re-translate if there's text
    if (_sourceText.trim().isNotEmpty) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _performTranslation();
      });
    }
  }

  void clearText() {
    _sourceText = '';
    _translatedText = '';
    _errorMessage = null;
    _isLoading = false;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  Future<void> _performTranslation() async {
    if (_sourceText.trim().isEmpty) {
      _translatedText = '';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _papagoService.translate(
        text: _sourceText,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
      );

      _translatedText = result;
      _isLoading = false;
      notifyListeners();

      // Save translation to backend (non-blocking)
      _saveToBackend();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _translatedText = '';
      notifyListeners();
    }
  }

  /// Save translation to backend asynchronously (doesn't block UI)
  Future<void> _saveToBackend() async {
    // Don't save if not authenticated or translation is empty
    if (!_backendService.isAuthenticated ||
        _sourceText.trim().isEmpty ||
        _translatedText.trim().isEmpty) {
      return;
    }

    try {
      await _backendService.saveTranslation(
        sourceText: _sourceText,
        translatedText: _translatedText,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
      );
      if (kDebugMode) {
        print('Translation saved to backend successfully');
      }
    } catch (e) {
      // Silently fail - don't interrupt user experience
      if (kDebugMode) {
        print('Failed to save translation to backend: $e');
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
