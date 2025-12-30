class VocabularyItem {
  final String id;
  final String word;
  final String translation;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime firstSeen;
  final DateTime lastReviewed;
  final int reviewCount;
  final bool isMastered;

  VocabularyItem({
    required this.id,
    required this.word,
    required this.translation,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.firstSeen,
    required this.lastReviewed,
    this.reviewCount = 0,
    this.isMastered = false,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      word: json['word'] as String,
      translation: json['translation'] as String,
      sourceLanguage: json['source_lang'] as String,
      targetLanguage: json['target_lang'] as String,
      firstSeen: DateTime.parse(json['created'] as String), // Using created as firstSeen
      lastReviewed: DateTime.parse(json['updated'] as String), // Using updated as lastReviewed
      reviewCount: json['review_count'] as int? ?? 0,
      isMastered: json['is_mastered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'translation': translation,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'firstSeen': firstSeen.toIso8601String(),
      'lastReviewed': lastReviewed.toIso8601String(),
      'reviewCount': reviewCount,
      'isMastered': isMastered,
    };
  }

  VocabularyItem copyWith({
    String? id,
    String? word,
    String? translation,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? firstSeen,
    DateTime? lastReviewed,
    int? reviewCount,
    bool? isMastered,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      firstSeen: firstSeen ?? this.firstSeen,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      isMastered: isMastered ?? this.isMastered,
    );
  }
}

