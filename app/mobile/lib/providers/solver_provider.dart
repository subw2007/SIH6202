import 'package:flutter/foundation.dart';

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
  SolverProvider()
    : _tasks = [
        const SolverTask(
          id: 'pothole-sector-4',
          title: 'Deep pothole causing accidents near school',
          timestamp: '2h ago',
          location: 'Sector 4, Main St',
          distance: '1.2 km',
          upvotes: 148,
          teamCount: 3,
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          category: SolverCategory.infrastructure,
          description:
              'Large road damage is disrupting traffic and creating a safety hazard for school commuters.',
        ),
        const SolverTask(
          id: 'streetlight-ward-8',
          title: 'Streetlight outage near school',
          timestamp: '4h ago',
          location: 'Ward 8, Lake Road',
          distance: '2.4 km',
          upvotes: 92,
          teamCount: 2,
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          category: SolverCategory.electricity,
          description:
              'Three lights are out along the pedestrian route used by students after sunset.',
        ),
        const SolverTask(
          id: 'drainage-market',
          title: 'Blocked drainage overflow',
          timestamp: 'Yesterday',
          location: 'Central Market, Block B',
          distance: '3.1 km',
          upvotes: 61,
          teamCount: 4,
          priority: TaskPriority.medium,
          status: TaskStatus.inProgress,
          category: SolverCategory.water,
          description:
              'Standing water is collecting around the market entrance after recent rainfall.',
        ),
        const SolverTask(
          id: 'garbage-park',
          title: 'Missed waste collection',
          timestamp: 'Yesterday',
          location: 'Green Park, Lane 2',
          distance: '4.8 km',
          upvotes: 38,
          teamCount: 1,
          priority: TaskPriority.low,
          status: TaskStatus.resolved,
          category: SolverCategory.sanitation,
          description:
              'Household waste was left uncollected at the scheduled pickup point.',
        ),
        const SolverTask(
          id: 'water-leak',
          title: 'Water leak on public walkway',
          timestamp: '2 days ago',
          location: 'Civic Centre, East Gate',
          distance: '5.2 km',
          upvotes: 44,
          teamCount: 2,
          priority: TaskPriority.medium,
          status: TaskStatus.resolved,
          category: SolverCategory.water,
          description:
              'A damaged pipe is causing water to pool on the public walkway.',
        ),
      ];

  final List<SolverTask> _tasks;
  SolverCategory _category = SolverCategory.all;

  List<SolverTask> get tasks => List.unmodifiable(_tasks);
  SolverCategory get category => _category;
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

  void setCategory(SolverCategory category) {
    if (_category == category) return;
    _category = category;
    notifyListeners();
  }

  void updateStatus(String taskId, TaskStatus status) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1 || _tasks[index].status == status) return;
    _tasks[index] = _tasks[index].copyWith(status: status);
    notifyListeners();
  }
}
