import 'package:flutter/foundation.dart';

import 'auth_provider.dart';
import '../services/api_service.dart';

class CitizenFeedProvider extends ChangeNotifier {
  CitizenFeedProvider({this.authProvider, ApiService? apiService})
    : _apiService = apiService ?? ApiService() {
    authProvider?.registerSessionReset(clear);
  }

  final AuthProvider? authProvider;
  final ApiService _apiService;
  List<Map<String, dynamic>> _reports = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clear() {
    _reports = const [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchCitizenFeed({
    String city = 'All',
    String category = 'All',
    String severity = 'All',
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await _apiService.fetchCitizenFeed(
        city: city,
        category: category,
        severity: severity,
      );
    } catch (_) {
      _errorMessage =
          'Unable to load reports. Check the backend and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    authProvider?.unregisterSessionReset(clear);
    _apiService.dispose();
    super.dispose();
  }
}
