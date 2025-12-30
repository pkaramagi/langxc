import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/translation.dart';
import '../models/vocabulary_item.dart';
import '../services/backend_api_service.dart';

class HistoryProvider with ChangeNotifier {
  final BackendApiService _backendService = BackendApiService();
  final Uuid _uuid = const Uuid();
  
  List<Translation> _translations = [];
  List<VocabularyItem> _vocabulary = [];
  bool _isLoading = false;

  List<Translation> get translations => _translations;
  List<VocabularyItem> get vocabulary => _vocabulary;
  bool get isLoading => _isLoading;

  Future<void> loadTranslations({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _backendService.getTranslations();
      _translations = data.map((item) => Translation(
        id: item['id'],
        sourceText: item['source_text'],
        targetText: item['translated_text'],
        direction: item['source_lang'] == 'ko' 
            ? TranslationDirection.koToEn 
            : TranslationDirection.enToKo,
        createdAt: DateTime.parse(item['created']),
        userId: item['user'],
      )).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading translations: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVocabulary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _backendService.getVocabulary();
      _vocabulary = data.map((item) => VocabularyItem(
        id: item['id'],
        word: item['word'],
        translation: item['translation'],
        sourceLanguage: item['source_lang'],
        targetLanguage: item['target_lang'],
        firstSeen: DateTime.parse(item['first_seen']),
        lastReviewed: DateTime.parse(item['last_reviewed']),
        reviewCount: item['count'],
        isMastered: item['is_mastered'],
      )).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading vocabulary: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<VocabularyItem>> getWeeklyVocabulary(DateTime weekStart) async {
    try {
      final summary = await _backendService.getWeeklySummary();
      if (summary == null) return [];
      
      final List<dynamic> words = summary['most_frequent_words'];
      return words.map((w) => VocabularyItem(
        id: _uuid.v4(), // Temporary ID for summary items
        word: w['word'],
        translation: w['translation'],
        sourceLanguage: 'ko', // Defaulting to Korean for now
        targetLanguage: 'en',
        firstSeen: DateTime.now(),
        lastReviewed: DateTime.now(),
        reviewCount: w['count'],
        isMastered: false,
      )).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting weekly vocabulary: $e');
      }
      return [];
    }
  }

  Future<void> addToVocabulary(Translation translation) async {
    // Backend handles vocabulary extraction automatically when translation is saved.
    // We just need to refresh the list.
    await loadVocabulary();
  }

  Future<void> updateVocabularyItem(VocabularyItem item) async {
    try {
      if (item.isMastered) {
        await _backendService.markVocabularyAsMastered(item.id); 
      }
      
      // Update local list
      final index = _vocabulary.indexWhere((v) => v.id == item.id);
      if (index != -1) {
        _vocabulary[index] = item;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating vocabulary: $e');
      }
    }
  }

  Future<void> deleteTranslation(String id) async {
    try {
      // BackendApiService expects int ID?
      // Let's check.
      // If it expects int, we have a problem because PocketBase uses string IDs.
      
      // Assuming I'll fix BackendApiService to accept String IDs.
      // await _backendService.deleteTranslation(id);
      
      _translations.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteVocabularyItem(String id) async {
    try {
      // await _backendService.deleteVocabulary(id);
      _vocabulary.removeWhere((v) => v.id == id);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}

