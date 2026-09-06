import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // 1. Checks both 'BASE_URL' and 'API_BASE_URL' flags from --dart-define
  // 2. Fallbacks to LAN IP (10.206.25.54) instead of localhost
  static String get _rawBaseUrl {
    const fromBaseUrl = String.fromEnvironment('BASE_URL');
    if (fromBaseUrl.isNotEmpty) {
      return fromBaseUrl.endsWith('/api') ? fromBaseUrl : '$fromBaseUrl/api';
    }

    const fromApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (fromApiBaseUrl.isNotEmpty) {
      return fromApiBaseUrl.endsWith('/api')
          ? fromApiBaseUrl
          : '$fromApiBaseUrl/api';
    }

    return 'http://10.206.25.54:5001/api';
  }

  static final baseUrl = _rawBaseUrl;

  final http.Client _client;
  static String? _token;

  static void setToken(String? token) => _token = token;

  Map<String, String> _headers([Map<String, String>? extra]) => {
        if (_token != null) 'Authorization': 'Bearer $_token',
        ...?extra,
      };

  Future<Map<String, dynamic>> login(String email, String password) =>
      _authenticate('/auth/login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) => _authenticate('/auth/signup', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _client.get(Uri.parse('$baseUrl/auth/me'), headers: _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Session expired');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> _authenticate(
    String path,
    Map<String, String> data,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers({'Content-Type': 'application/json'}),
      body: jsonEncode(data),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      throw Exception(decoded is Map ? decoded['error'] : 'Authentication failed');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static String resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final gatewayUrl = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;
    return '$gatewayUrl$url';
  }

  Future<String> uploadFile(XFile file) async {
    final result = await uploadMedia(file);
    return result['url']!.toString();
  }

  Future<String> transcribeAudio(XFile file) async {
    final audioUrl = await uploadFile(file);
    final response = await _client.post(
      Uri.parse('$baseUrl/transcribe'),
      headers: _headers({'Content-Type': 'application/json'}),
      body: jsonEncode({'audio_url': audioUrl}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Transcription failed with status ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['transcript'] is! String) {
      throw const FormatException(
        'Transcription response must contain a transcript',
      );
    }
    return decoded['transcript'] as String;
  }

  Future<Map<String, String>> uploadMedia(XFile file) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'))
      ..headers.addAll(_headers());
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ),
    );
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload failed with status ${response.statusCode}');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map || decoded['url'] == null) {
      throw const FormatException('Upload response must contain a URL');
    }
    final url = resolveMediaUrl(decoded['url'].toString());
    final result = <String, String>{'url': url};
    if (decoded['video_url'] != null) {
      result['video_url'] = resolveMediaUrl(decoded['video_url'].toString());
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> fetchReports({
    String city = 'All',
    String category = 'All',
    String severity = 'All',
  }) async {
    final uri = Uri.parse('$baseUrl/reports').replace(
      queryParameters: {
        if (city != 'All') 'city': city,
        if (category != 'All') 'category': category,
        if (severity != 'All') 'severity': severity,
      },
    );
    try {
      final response = await _client.get(uri, headers: _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed with status ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Citizen feed must be a JSON array');
      }

      final reports = decoded
          .whereType<Map>()
          .map((report) => Map<String, dynamic>.from(report))
          .toList();
      _logSuccess('GET /reports (${reports.length} reports)');
      return reports;
    } catch (error) {
      _logError('GET /reports', error);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCitizenFeed({
    String city = 'All',
    String category = 'All',
    String severity = 'All',
  }) => fetchReports(city: city, category: category, severity: severity);

  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/reports');
    try {
      final response = await _client.post(
        uri,
        headers: _headers({'Content-Type': 'application/json'}),
        body: jsonEncode(data),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed with status ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Created report must be a JSON object');
      }

      final report = Map<String, dynamic>.from(decoded);
      _logSuccess('POST /reports (${response.statusCode})');
      return report;
    } catch (error) {
      _logError('POST /reports', error);
      rethrow;
    }
  }

  Future<String> categorizeText(String text) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/reports/categorize'),
      headers: _headers({'Content-Type': 'application/json'}),
      body: jsonEncode({'description': text}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['category'] is! String) {
      throw const FormatException(
        'Categorization response must contain a category',
      );
    }
    return decoded['category'] as String;
  }

  Future<String> summarizeText(String rawText) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/reports/summarize'),
      headers: _headers({'Content-Type': 'application/json'}),
      body: jsonEncode({'rawText': rawText}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['summary'] is! String) {
      throw const FormatException('Summary response must contain a summary');
    }
    return decoded['summary'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchComments(String reportId) async {
    final uri = Uri.parse(
      '$baseUrl/reports/${Uri.encodeComponent(reportId)}/comments',
    );
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Comments must be a JSON array');
    }
    return decoded
        .whereType<Map>()
        .map((comment) => Map<String, dynamic>.from(comment))
        .toList();
  }

  Future<Map<String, dynamic>> addComment({
    required String reportId,
    required String text,
    required String? authorName,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/reports/${Uri.encodeComponent(reportId)}/comments',
    );
    final response = await _client.post(
      uri,
      headers: _headers({'Content-Type': 'application/json'}),
      body: jsonEncode({'text': text, 'author_name': authorName}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Created comment must be a JSON object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<List<Map<String, dynamic>>> fetchSolverTasks({
    String city = 'All',
    String category = 'All',
    String severity = 'All',
  }) => fetchReports(city: city, category: category, severity: severity);

  Future<List<Map<String, dynamic>>> fetchTeams(String reportId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/reports/${Uri.encodeComponent(reportId)}/teams'),
      headers: _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const FormatException('Teams must be a JSON array');
    return decoded
        .whereType<Map>()
        .map((team) => Map<String, dynamic>.from(team))
        .toList();
  }

  Future<Map<String, dynamic>> createTeam({
    required String reportId,
    required String name,
    required String institution,
    required String leadName,
    required String contact,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/reports/${Uri.encodeComponent(reportId)}/teams'),
      headers: _headers({'Content-Type': 'application/json'}),
      body: jsonEncode({
        'name': name,
        'institution': institution,
        'lead_name': leadName,
        'contact': contact,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Created team must be a JSON object');
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> joinTeam(String teamId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/teams/${Uri.encodeComponent(teamId)}/join'),
      headers: _headers({'Content-Type': 'application/json'}),
      body: jsonEncode({}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyTeams() async {
    final response = await _client.get(Uri.parse('$baseUrl/users/me/teams'), headers: _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const FormatException('User teams must be a JSON array');
    return decoded
        .whereType<Map>()
        .map((team) => Map<String, dynamic>.from(team))
        .toList();
  }

  Future<Map<String, dynamic>> updateTaskStatus(
    String id,
    String status,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/solver-tasks/${Uri.encodeComponent(id)}/status',
    );
    try {
      final response = await _client.patch(
        uri,
        headers: _headers({'Content-Type': 'application/json'}),
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed with status ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Updated task must be a JSON object');
      }
      final task = Map<String, dynamic>.from(decoded);
      _logSuccess('PATCH /solver-tasks/$id/status (${response.statusCode})');
      return task;
    } catch (error) {
      _logError('PATCH /solver-tasks/$id/status', error);
      rethrow;
    }
  }

  void dispose() => _client.close();

  void _logSuccess(String message) => debugPrint('[API SUCCESS] $message');

  void _logError(String endpoint, Object error) {
    debugPrint('[API ERROR] $endpoint: $error');
  }
}
