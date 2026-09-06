import 'package:flutter/foundation.dart';

import 'auth_provider.dart';
import '../services/api_service.dart';

class TeamMembership {
  const TeamMembership({required this.id, required this.reportId, required this.name});

  final String id;
  final String reportId;
  final String name;
}

class TeamsProvider extends ChangeNotifier {
  TeamsProvider({this.authProvider, ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    authProvider?.registerSessionReset(clear);
    refresh();
  }

  final AuthProvider? authProvider;
  final ApiService _apiService;
  final List<TeamMembership> _memberships = [];
  bool _isLoading = false;

  List<String> get userTeamIds => _memberships.map((team) => team.id).toList();
  bool get isLoading => _isLoading;

  void clear() {
    _memberships.clear();
    notifyListeners();
  }

  TeamMembership? membershipForReport(String reportId) {
    for (final membership in _memberships) {
      if (membership.reportId == reportId) return membership;
    }
    return null;
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final teams = await _apiService.fetchMyTeams();
      _memberships
        ..clear()
        ..addAll(teams.map((team) => TeamMembership(
              id: team['id'].toString(),
              reportId: team['report_id']?.toString() ?? '',
              name: team['name']?.toString() ?? 'Team',
            )));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> join(String teamId) async {
    await _apiService.joinTeam(teamId);
    await refresh();
  }

  @override
  void dispose() {
    authProvider?.unregisterSessionReset(clear);
    _apiService.dispose();
    super.dispose();
  }
}
