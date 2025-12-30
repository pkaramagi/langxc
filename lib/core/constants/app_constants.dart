class AppConstants {
  // Papago API Configuration
  static const String papagoApiUrl = 'https://openapi.naver.com/v1/papago/n2mt';
  static const String papagoDetectUrl =
      'https://openapi.naver.com/v1/papago/detectLangs';

  // Storage Keys
  static const String translationsBoxName = 'translations';
  static const String vocabularyBoxName = 'vocabulary';
  static const String userPrefsKey = 'user_prefs';

  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String historyRoute = '/history';
  static const String weeklySummaryRoute = '/weekly-summary';
  static const String vocabularyRoute = '/vocabulary';
  static const String settingsRoute = '/settings';
  static const String notificationSummaryRoute = '/notification-summary';

  // Note: Papago API credentials should be managed by the backend proxy.
  // Do not store sensitive keys in the client-side code in production.
  static const String papagoClientId = 'REMOVED';
  static const String papagoClientSecret = 'REMOVED';
}
