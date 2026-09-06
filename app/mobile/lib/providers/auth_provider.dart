import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    _restoreSession();
  }

  final ApiService _apiService;
  final List<VoidCallback> _sessionResetters = [];
  Map<String, dynamic>? _currentUser;
  String? _token;
  bool _isLoading = true;

  Map<String, dynamic>? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;

  void registerSessionReset(VoidCallback resetter) {
    if (!_sessionResetters.contains(resetter)) _sessionResetters.add(resetter);
  }

  void unregisterSessionReset(VoidCallback resetter) {
    _sessionResetters.remove(resetter);
  }

  Future<void> _restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final storedToken = preferences.getString('jwt');
    if (storedToken != null) {
      try {
        ApiService.setToken(storedToken);
        final profile = await _apiService.getCurrentUser();
        _token = storedToken;
        _currentUser = profile;
      } catch (_) {
        await preferences.remove('jwt');
        ApiService.setToken(null);
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await _apiService.login(email.trim(), password);
    await _saveSession(result);
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final result = await _apiService.signup(
      name: name.trim(),
      email: email.trim(),
      password: password,
      role: role,
    );
    await _saveSession(result);
  }

  Future<void> _saveSession(Map<String, dynamic> result) async {
    final newToken = result['jwt']?.toString();
    final user = result['user'];
    if (newToken == null || user is! Map) throw const FormatException('Invalid authentication response');
    _token = newToken;
    _currentUser = Map<String, dynamic>.from(user);
    ApiService.setToken(newToken);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('jwt', newToken);
    notifyListeners();
  }

  Future<void> logout() async {
    for (final resetter in List<VoidCallback>.from(_sessionResetters)) {
      resetter();
    }
    _token = null;
    _currentUser = null;
    ApiService.setToken(null);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('jwt');
    notifyListeners();
  }
}