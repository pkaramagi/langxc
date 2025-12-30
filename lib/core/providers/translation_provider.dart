import 'package:flutter/foundation.dart';
import '../models/translation.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';
import '../services/backend_api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TranslationProvider with ChangeNotifier {
  final TranslationService _translationService = TranslationService();
  final StorageService _storageService = StorageService();
  final BackendApiService _backendService = BackendApiService();
  final Connectivity _connectivity = Connectivity();

  Translation? _currentTranslation;
  bool _isTranslating = false;
  String? _errorMessage;
  TranslationDirection _currentDirection = TranslationDirection.koToEn;
  bool _isOnline = true;
  List<Translation> _pendingSync = [];
  bool _isSyncing = false;

  Translation? get currentTranslation => _currentTranslation;
  bool get isTranslating => _isTranslating;
  String? get errorMessage => _errorMessage;
  TranslationDirection get currentDirection => _currentDirection;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingSyncCount => _pendingSync.length;

  Future<void> init() async {
    await _backendService.init();
    await _checkConnectivity();
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    await _loadPendingSync();
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    notifyListeners();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    notifyListeners();

    // If we just came back online, try to sync pending translations
    if (!wasOnline && _isOnline && _pendingSync.isNotEmpty) {
      _syncPendingTranslations();
    }
  }

  Future<void> _loadPendingSync() async {
    // Load pending sync items from storage
    // For now, we'll track them in memory, but in a real app you'd persist this
    _pendingSync = [];
    notifyListeners();
  }

  Future<void> translate({
    required String text,
    TranslationDirection? direction,
    String? userId,
  }) async {
    if (text.trim().isEmpty) return;

    _isTranslating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Auto-detect direction if not specified
      TranslationDirection dir = direction ?? _currentDirection;
      if (direction == null) {
        final detectedLang = await _translationService.detectLanguage(text);
        dir = detectedLang == 'ko'
            ? TranslationDirection.koToEn
            : TranslationDirection.enToKo;
        _currentDirection = dir;
      }

      var translation = await _translationService.translate(
        text: text,
        direction: dir,
      );

      if (userId != null) {
        translation = Translation(
          id: translation.id,
          sourceText: translation.sourceText,
          targetText: translation.targetText,
          direction: translation.direction,
          createdAt: translation.createdAt,
          userId: userId,
        );
      }

      _currentTranslation = translation;

      // Save to local storage first (instant feedback)
      await _storageService.saveTranslation(translation);

      // Queue for backend sync (hybrid approach)
      if (userId != null) {
        await _queueForSync(translation);
      }

      _isTranslating = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isTranslating = false;
      notifyListeners();
    }
  }

  void setDirection(TranslationDirection direction) {
    _currentDirection = direction;
    notifyListeners();
  }

  void clearTranslation() {
    _currentTranslation = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Hybrid sync methods
  Future<void> _queueForSync(Translation translation) async {
    // Only add if not already in pending sync
    if (!_pendingSync.any((t) => t.id == translation.id)) {
      _pendingSync.add(translation);
      notifyListeners();
    }

    // Try to sync immediately if online, otherwise it will sync when connection is restored
    if (_isOnline && !_isSyncing) {
      await _syncPendingTranslations();
    }
  }

  Future<void> _syncPendingTranslations() async {
    if (_isSyncing ||
        _pendingSync.isEmpty ||
        !_backendService.isAuthenticated) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final successfulSyncs = <Translation>[];

      for (final translation in _pendingSync) {
        try {
          final success = await _backendService.syncTranslation(translation);
          if (success) {
            successfulSyncs.add(translation);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to sync translation ${translation.id}: $e');
          }
          // Continue with other translations
        }
      }

      // Remove successfully synced translations
      _pendingSync.removeWhere((t) => successfulSyncs.contains(t));
      if (kDebugMode) {
        print(
          'Sync completed. ${successfulSyncs.length} translations synced, ${_pendingSync.length} remaining',
        );
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Sync error: $e');
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Manual sync trigger (can be called from UI)
  Future<void> syncNow() async {
    if (_isOnline && !_isSyncing) {
      await _syncPendingTranslations();
    }
  }

  // Force sync all translations (for initial data migration)
  Future<void> syncAllLocalTranslations(String userId) async {
    if (!_backendService.isAuthenticated) return;

    try {
      final allTranslations = await _storageService.getTranslations(
        userId: userId,
      );
      final unsyncedTranslations = allTranslations
          .where((t) => !_pendingSync.any((pending) => pending.id == t.id))
          .toList();

      if (unsyncedTranslations.isNotEmpty) {
        _pendingSync.addAll(unsyncedTranslations);
        notifyListeners();
        await _syncPendingTranslations();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync all translations: $e');
      }
    }
  }
}
