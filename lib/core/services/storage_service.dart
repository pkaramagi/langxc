import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation.dart';
import '../models/vocabulary_item.dart';
import '../constants/app_constants.dart';

class StorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(AppConstants.translationsBoxName);
    await Hive.openBox<Map>(AppConstants.vocabularyBoxName);
  }

  // Translation History Storage
  Future<void> saveTranslation(Translation translation) async {
    final box = Hive.box<Map>(AppConstants.translationsBoxName);
    await box.put(translation.id, translation.toJson());
  }

  Future<List<Translation>> getTranslations({String? userId}) async {
    final box = Hive.box<Map>(AppConstants.translationsBoxName);
    final translations = <Translation>[];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final translation = Translation.fromJson(Map<String, dynamic>.from(data));
        if (userId == null || translation.userId == userId) {
          translations.add(translation);
        }
      }
    }
    
    translations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return translations;
  }

  Future<void> deleteTranslation(String id) async {
    final box = Hive.box<Map>(AppConstants.translationsBoxName);
    await box.delete(id);
  }

  // Vocabulary Storage
  Future<void> saveVocabularyItem(VocabularyItem item) async {
    final box = Hive.box<Map>(AppConstants.vocabularyBoxName);
    await box.put(item.id, item.toJson());
  }

  Future<List<VocabularyItem>> getVocabularyItems() async {
    final box = Hive.box<Map>(AppConstants.vocabularyBoxName);
    final items = <VocabularyItem>[];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        items.add(VocabularyItem.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    
    return items;
  }

  Future<List<VocabularyItem>> getWeeklyVocabulary(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final allItems = await getVocabularyItems();
    
    return allItems.where((item) {
      return item.firstSeen.isAfter(weekStart) && item.firstSeen.isBefore(weekEnd);
    }).toList();
  }

  Future<void> deleteVocabularyItem(String id) async {
    final box = Hive.box<Map>(AppConstants.vocabularyBoxName);
    await box.delete(id);
  }

  // SharedPreferences for user preferences
  Future<void> saveUserPreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getUserPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> clearAll() async {
    final translationsBox = Hive.box<Map>(AppConstants.translationsBoxName);
    final vocabularyBox = Hive.box<Map>(AppConstants.vocabularyBoxName);
    await translationsBox.clear();
    await vocabularyBox.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

