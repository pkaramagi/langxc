enum TranslationDirection {
  koToEn,
  enToKo,
}

class Translation {
  final String id;
  final String sourceText;
  final String targetText;
  final TranslationDirection direction;
  final DateTime createdAt;
  final String? userId;

  Translation({
    required this.id,
    required this.sourceText,
    required this.targetText,
    required this.direction,
    required this.createdAt,
    this.userId,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      id: json['id'] as String,
      sourceText: json['source_text'] as String,
      targetText: json['translated_text'] as String,
      direction: (json['source_lang'] == 'ko') 
          ? TranslationDirection.koToEn 
          : TranslationDirection.enToKo,
      createdAt: DateTime.parse(json['created'] as String),
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceText': sourceText,
      'targetText': targetText,
      'direction': direction.toString(),
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  String get sourceLanguage => direction == TranslationDirection.koToEn ? 'ko' : 'en';
  String get targetLanguage => direction == TranslationDirection.koToEn ? 'en' : 'ko';
}

