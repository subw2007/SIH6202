import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

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
  );
}

class SolverProvider extends ChangeNotifier {
  SolverProvider() : _tasks = [] {
    fetchTasks();
  }

  final List<SolverTask> _tasks;
  SolverCategory _category = SolverCategory.all;
  bool _isLoading = false;
  String? _error;

  List<SolverTask> get tasks => List.unmodifiable(_tasks);
  SolverCategory get category => _category;
  bool get isLoading => _isLoading;
  String? get error => _error;
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

  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final category = _category.name;
      final tasks = await ApiService.instance.fetchSolverTasks(category: category);
      _tasks
        ..clear()
        ..addAll(tasks);
    } catch (error) {
      _error = 'Unable to load solver tasks. Please try again.';
      debugPrint('[SOLVER PROVIDER ERROR] $error');
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

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1 || _tasks[index].status == status) return;
    final previous = _tasks[index];
    _tasks[index] = _tasks[index].copyWith(status: status);
    notifyListeners();
    try {
      await ApiService.instance.updateTaskStatus(taskId, status.name);
    } catch (error) {
      _tasks[index] = previous;
      _error = 'Unable to update task status. Please try again.';
      debugPrint('[SOLVER PROVIDER ERROR] $error');
      notifyListeners();
    }
  }
}
