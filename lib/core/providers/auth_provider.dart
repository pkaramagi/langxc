import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_user;
import '../services/backend_api_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider() : _backendService = BackendApiService() {
    _init();
  }

  final BackendApiService _backendService;
  app_user.User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  app_user.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<void> _init() async {
    await _backendService.init();
    if (_backendService.isAuthenticated) {
      await _loadUser();
    }
  }

  Future<void> _loadUser() async {
    try {
      final userData = await _backendService.getCurrentUser();
      if (userData != null) {
        _user = app_user.User(
          id: userData['id'],
          email: userData['email'],
          displayName: userData['display_name'],
          createdAt: DateTime.parse(userData['created']),
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user: $e');
      }
    }
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _backendService.login(email: email, password: password);
      if (success) {
        await _loadUser();
        _setLoading(false);
        return true;
      } else {
        _setError('Invalid email or password');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _backendService.register(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (success) {
        await _loadUser();
        _setLoading(false);
        return true;
      } else {
        _setError('Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setError('Google Sign-In is not currently supported with this backend.');
    return false;
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _backendService.clearToken();
    _user = null;
    _setLoading(false);
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    _setError('Password reset is not currently supported with this backend.');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
