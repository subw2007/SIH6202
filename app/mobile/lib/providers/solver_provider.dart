import 'package:flutter/foundation.dart';

import 'auth_provider.dart';
import '../services/api_service.dart';
import '../services/report_author.dart';

enum TaskPriority { critical, high, medium, low }

enum TaskStatus { pending, inProgress, resolved }

enum SolverCategory { all, infrastructure, water, electricity, sanitation }

class SolverTask {
  const SolverTask({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.location,
    required this.distance,
    required this.upvotes,
    required this.teamCount,
    required this.priority,
    required this.status,
    required this.category,
    required this.description,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.commentCount = 0,
    this.authorName = 'Anonymous Citizen',
  });

  final String id;
  final String title;
  final String timestamp;
  final String location;
  final String distance;
  final int upvotes;
  final int teamCount;
  final TaskPriority priority;
  final TaskStatus status;
  final SolverCategory category;
  final String description;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final int commentCount;
  final String authorName;

  SolverTask copyWith({TaskStatus? status}) => SolverTask(
    id: id,
    title: title,
    timestamp: timestamp,
    location: location,
    distance: distance,
    upvotes: upvotes,
    teamCount: teamCount,
    priority: priority,
    status: status ?? this.status,
    category: category,
    description: description,
    imageUrl: imageUrl,
    audioUrl: audioUrl,
    videoUrl: videoUrl,
    commentCount: commentCount,
    authorName: authorName,
  );

  factory SolverTask.fromJson(Map<String, dynamic> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final coordinate = latitude != null && longitude != null
        ? '$latitude, $longitude'
        : 'Location unavailable';
    final location = json['location_name']?.toString().trim().isNotEmpty == true
        ? json['location_name'].toString()
        : coordinate;
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');

    return SolverTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString()
          : 'Untitled report',
      timestamp: createdAt == null ? 'Just now' : _timeAgo(createdAt),
      location: location,
      distance: location,
      upvotes: _asInt(json['upvotes']),
      teamCount: _asInt(json['team_count']),
      priority: _parsePriority(json['priority']),
      status: _parseStatus(json['status']),
      category: _parseCategory(json['category']),
      description: json['description']?.toString().trim().isNotEmpty == true
          ? json['description'].toString()
          : 'No additional description provided.',
      imageUrl: ApiService.resolveMediaUrl(json['image_url']?.toString()),
      audioUrl: ApiService.resolveMediaUrl(json['audio_url']?.toString()),
      videoUrl: ApiService.resolveMediaUrl(json['video_url']?.toString()),
      commentCount: _asInt(json['comment_count']),
      authorName: reportAuthorName(json),
    );
  }

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;

  static TaskPriority _parsePriority(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'critical':
        return TaskPriority.critical;
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  static TaskStatus _parseStatus(Object? value) {
    switch (value?.toString().toUpperCase()) {
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'RESOLVED':
        return TaskStatus.resolved;
      default:
        return TaskStatus.pending;
    }
  }

  static SolverCategory _parseCategory(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'infrastructure':
        return SolverCategory.infrastructure;
      case 'water':
        return SolverCategory.water;
      case 'electricity':
      case 'lighting':
        return SolverCategory.electricity;
      case 'sanitation':
      case 'waste':
        return SolverCategory.sanitation;
      default:
        return SolverCategory.all;
    }
  }

  static String _timeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class SolverProvider extends ChangeNotifier {
  SolverProvider({this.authProvider, ApiService? apiService})
    : _apiService = apiService ?? ApiService() {
    authProvider?.registerSessionReset(clear);
    fetchTasks();
  }

  final AuthProvider? authProvider;
  final ApiService _apiService;
  final List<SolverTask> _tasks = [];
  final Set<String> _updatingTaskIds = {};
  SolverCategory _category = SolverCategory.all;
  bool _isLoading = false;
  String? _errorMessage;

  List<SolverTask> get tasks => List.unmodifiable(_tasks);
  SolverCategory get category => _category;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool isUpdating(String taskId) => _updatingTaskIds.contains(taskId);

  void clear() {
    _tasks.clear();
    _updatingTaskIds.clear();
    _errorMessage = null;
    notifyListeners();
  }

  int get highPriorityCount => _tasks
      .where(
        (task) =>
            task.priority == TaskPriority.high ||
            task.priority == TaskPriority.critical,
      )
      .length;

  List<SolverTask> get visibleTasks => _tasks
      .where(
        (task) => _category == SolverCategory.all || task.category == _category,
      )
      .toList();

  Future<void> fetchTasks({
    String city = 'All',
    String category = 'All',
    String severity = 'All',
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reports = await _apiService.fetchSolverTasks(
        city: city,
        category: category,
        severity: severity,
      );
      _tasks
        ..clear()
        ..addAll(reports.map(SolverTask.fromJson));
    } catch (_) {
      _errorMessage =
          'Unable to load solver tasks. Check the backend and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(SolverCategory category) {
    if (_category == category) return;
    _category = category;
    notifyListeners();
  }

  Future<bool> updateStatus(String taskId, TaskStatus status) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1 || _tasks[index].status == status) return true;

    _updatingTaskIds.add(taskId);
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.updateTaskStatus(
        taskId,
        _statusValue(status),
      );
      _tasks[index] = _tasks[index].copyWith(
        status: SolverTask._parseStatus(response['status']),
      );
      return true;
    } catch (_) {
      _errorMessage = 'Unable to update this task. Please try again.';
      return false;
    } finally {
      _updatingTaskIds.remove(taskId);
      notifyListeners();
    }
  }

  static String _statusValue(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'PENDING';
      case TaskStatus.inProgress:
        return 'IN_PROGRESS';
      case TaskStatus.resolved:
        return 'RESOLVED';
    }
  }

  @override
  void dispose() {
    authProvider?.unregisterSessionReset(clear);
    _apiService.dispose();
    super.dispose();
  }
}
