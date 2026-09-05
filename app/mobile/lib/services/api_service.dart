import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../providers/solver_provider.dart';
import '../views/widgets/citizen_problem_card.dart';

class ApiException implements Exception {
  const ApiException(this.message, {required this.uri, required this.statusCode});

  final String message;
  final Uri uri;
  final int statusCode;

  @override
  String toString() => message;
}

/// Backend API client for the CivicPulse mobile app.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5001/api',
  );

  Future<List<CitizenProblemPost>> fetchCitizenFeed() async {
    final uri = Uri.parse('$baseUrl/citizen-feed');
    final response = await _get(uri);
    final items = _dataList(response, uri);
    return items.map(_toCitizenPost).toList();
  }

  Future<bool> submitReport(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/reports');
    await _post(uri, payload);
    return true;
  }

  Future<List<SolverTask>> fetchSolverTasks({String category = 'all'}) async {
    final uri = Uri.parse('$baseUrl/solver-tasks').replace(
      queryParameters: category.toLowerCase() == 'all'
          ? null
          : {'category': category},
    );
    final response = await _get(uri);
    final items = _dataList(response, uri);
    return items.map(_toSolverTask).toList();
  }

  Future<bool> updateTaskStatus(String taskId, String status) async {
    final uri = Uri.parse('$baseUrl/solver-tasks/$taskId/status');
    await _patch(uri, {'status': status});
    return true;
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      final response = await http.get(uri);
      return _checked(response, uri);
    } on SocketException catch (error) {
      _logError(uri, null, error);
      rethrow;
    } on http.ClientException catch (error) {
      _logError(uri, null, error);
      rethrow;
    } catch (error) {
      _logError(uri, null, error);
      rethrow;
    }
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return _checked(response, uri);
    } on SocketException catch (error) {
      _logError(uri, null, error);
      rethrow;
    } on http.ClientException catch (error) {
      _logError(uri, null, error);
      rethrow;
    } catch (error) {
      _logError(uri, null, error);
      rethrow;
    }
  }

  Future<http.Response> _patch(Uri uri, Map<String, dynamic> payload) async {
    try {
      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return _checked(response, uri);
    } on SocketException catch (error) {
      _logError(uri, null, error);
      rethrow;
    } on http.ClientException catch (error) {
      _logError(uri, null, error);
      rethrow;
    } catch (error) {
      _logError(uri, null, error);
      rethrow;
    }
  }

  http.Response _checked(http.Response response, Uri uri) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint(
        '[API SERVICE SUCCESS] ${uri.toString()} ${response.statusCode} ${response.body}',
      );
      return response;
    }
    _logError(uri, response.statusCode, response.body);
    throw ApiException(
      'Request failed with status ${response.statusCode}',
      uri: uri,
      statusCode: response.statusCode,
    );
  }

  List<Map<String, dynamic>> _dataList(http.Response response, Uri uri) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
      throw FormatException('Invalid API response from $uri');
    }
    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  CitizenProblemPost _toCitizenPost(Map<String, dynamic> map) {
    return CitizenProblemPost(
      id: map['id']?.toString() ?? 'rpt_unknown',
      title: map['title']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      timeAgo: map['timeAgo']?.toString() ?? map['time_ago']?.toString() ?? 'Recently',
      upvoteCount: _asInt(map['upvoteCount'] ?? map['upvote_count']),
      audioDuration: map['audioDuration']?.toString() ?? map['audio_duration']?.toString() ?? '0:00',
      isVerified: map['isVerified'] as bool? ?? map['is_verified'] as bool? ?? false,
      imageUrl: map['imageUrl']?.toString() ?? map['image_url']?.toString(),
    );
  }

  SolverTask _toSolverTask(Map<String, dynamic> map) {
    final priority = switch (map['priority']?.toString().toLowerCase()) {
      'critical' => TaskPriority.critical,
      'high' => TaskPriority.high,
      'low' => TaskPriority.low,
      _ => TaskPriority.medium,
    };
    final status = switch (map['status']?.toString()) {
      'inProgress' || 'in_progress' => TaskStatus.inProgress,
      'resolved' => TaskStatus.resolved,
      _ => TaskStatus.pending,
    };
    final category = switch (map['category']?.toString().toLowerCase()) {
      'water' => SolverCategory.water,
      'electricity' => SolverCategory.electricity,
      'sanitation' => SolverCategory.sanitation,
      _ => SolverCategory.infrastructure,
    };
    return SolverTask(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      timestamp: map['timestamp']?.toString() ?? map['timeAgo']?.toString() ?? 'Recently',
      location: map['location']?.toString() ?? '',
      distance: map['distance']?.toString() ?? '1.0 km',
      upvotes: _asInt(map['upvotes'] ?? map['upvoteCount']),
      teamCount: _asInt(map['teamCount'] ?? map['team_count'], fallback: 1),
      priority: priority,
      status: status,
      category: category,
      description: map['description']?.toString() ?? '',
    );
  }

  static int _asInt(Object? value, {int fallback = 0}) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

  void _logError(Uri uri, int? statusCode, Object error) {
    debugPrint('[API SERVICE ERROR] ${uri.toString()} ${statusCode ?? '-'} $error');
  }
}
