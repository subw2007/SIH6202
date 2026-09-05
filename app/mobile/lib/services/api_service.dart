import 'dart:convert';
import 'dart:io';

import '../providers/solver_provider.dart';
import '../views/citizen_view.dart';
import '../views/widgets/citizen_problem_card.dart';

/// Backend API Client Service for CivicPulse Mobile App.
/// Connects to the Express MVC backend with zero-failure local mock fallbacks.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _defaultUrl = 'http://10.0.2.2:5000/api';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultUrl,
  );

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3);

  /// Fetch citizen feed from backend or return mock data on fallback
  Future<List<CitizenProblemPost>> fetchCitizenFeed() async {
    try {
      final uri = Uri.parse('$baseUrl/citizen-feed');
      final request = await _client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final List items = json['data'] as List? ?? [];

        return items.map((item) {
          final map = item as Map<String, dynamic>;
          return CitizenProblemPost(
            id: map['id']?.toString() ?? 'rpt_unknown',
            title: map['title']?.toString() ?? '',
            location: map['location']?.toString() ?? '',
            timeAgo: map['timeAgo']?.toString() ?? map['time_ago']?.toString() ?? 'Recently',
            upvoteCount: (map['upvoteCount'] ?? map['upvote_count'] ?? 0) as int,
            audioDuration: map['audioDuration']?.toString() ?? map['audio_duration']?.toString() ?? '0:00',
            isVerified: (map['isVerified'] ?? map['is_verified'] ?? false) as bool,
            imageUrl: map['imageUrl']?.toString() ?? map['image_url']?.toString(),
          );
        }).toList();
      }
    } catch (_) {
      // Graceful fallback to static mock data
    }
    return citizenFeedMock;
  }

  /// Submit new problem report to backend
  Future<bool> submitReport(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$baseUrl/reports');
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      // In offline / mock mode, succeed optimistically
      return true;
    }
  }

  /// Fetch solver tasks from backend
  Future<List<SolverTask>> fetchSolverTasks({String category = 'all'}) async {
    try {
      final queryParam = category.toLowerCase() != 'all' ? '?category=$category' : '';
      final uri = Uri.parse('$baseUrl/solver-tasks$queryParam');
      final request = await _client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final List items = json['data'] as List? ?? [];

        return items.map((item) {
          final map = item as Map<String, dynamic>;
          
          TaskPriority priority = TaskPriority.medium;
          final pStr = map['priority']?.toString().toLowerCase();
          if (pStr == 'critical') priority = TaskPriority.critical;
          if (pStr == 'high') priority = TaskPriority.high;
          if (pStr == 'low') priority = TaskPriority.low;

          TaskStatus status = TaskStatus.pending;
          final sStr = map['status']?.toString();
          if (sStr == 'inProgress' || sStr == 'in_progress') status = TaskStatus.inProgress;
          if (sStr == 'resolved') status = TaskStatus.resolved;

          SolverCategory cat = SolverCategory.infrastructure;
          final cStr = map['category']?.toString().toLowerCase();
          if (cStr == 'water') cat = SolverCategory.water;
          if (cStr == 'electricity') cat = SolverCategory.electricity;
          if (cStr == 'sanitation') cat = SolverCategory.sanitation;

          return SolverTask(
            id: map['id']?.toString() ?? '',
            title: map['title']?.toString() ?? '',
            timestamp: map['timestamp']?.toString() ?? map['timeAgo']?.toString() ?? 'Recently',
            location: map['location']?.toString() ?? '',
            distance: map['distance']?.toString() ?? '1.0 km',
            upvotes: (map['upvotes'] ?? map['upvoteCount'] ?? 0) as int,
            teamCount: (map['teamCount'] ?? map['team_count'] ?? 1) as int,
            priority: priority,
            status: status,
            category: cat,
            description: map['description']?.toString() ?? '',
          );
        }).toList();
      }
    } catch (_) {
      // Fallback handled in SolverProvider
    }
    return [];
  }

  /// Update task status
  Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      final uri = Uri.parse('$baseUrl/solver-tasks/$taskId/status');
      final request = await _client.patchUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode({'status': status})));
      final response = await request.close();
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }
}
