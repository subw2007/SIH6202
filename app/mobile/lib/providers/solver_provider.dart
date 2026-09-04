import 'package:flutter/foundation.dart';

enum SolverPriority { low, medium, high, critical }

enum SolverTaskStatus { pending, inProgress, resolved }

/// Inbox chips shown in Solver Workspace. Urgent is HIGH/CRITICAL + not resolved.
enum SolverFeedFilter { all, urgent, pending, inProgress, resolved }

class SolverTask {
  const SolverTask({
    required this.id,
    required this.title,
    required this.location,
    required this.timeAgo,
    required this.upvoteCount,
    required this.aiSummary,
    required this.priority,
    required this.status,
    this.assignedTeam,
  });

  final String id;
  final String title;
  final String location;
  final String timeAgo;
  final int upvoteCount;
  final String aiSummary;
  final SolverPriority priority;
  final SolverTaskStatus status;
  final String? assignedTeam;

  bool get isUrgent =>
      (priority == SolverPriority.high || priority == SolverPriority.critical) &&
      status != SolverTaskStatus.resolved;

  SolverTask copyWith({
    SolverTaskStatus? status,
    String? assignedTeam,
    bool clearTeam = false,
  }) {
    return SolverTask(
      id: id,
      title: title,
      location: location,
      timeAgo: timeAgo,
      upvoteCount: upvoteCount,
      aiSummary: aiSummary,
      priority: priority,
      status: status ?? this.status,
      assignedTeam: clearTeam ? null : (assignedTeam ?? this.assignedTeam),
    );
  }

  Map<String, dynamic> toMockJson() => {
        'id': id,
        'title': title,
        'location': location,
        'time_ago': timeAgo,
        'upvote_count': upvoteCount,
        'ai_summary': aiSummary,
        'priority': priority.name,
        'status': status.name,
        'assigned_team': assignedTeam,
      };
}

/// Municipal inbox: filter + resolution actions over a mocked task list.
class SolverProvider extends ChangeNotifier {
  SolverFeedFilter _filter = SolverFeedFilter.all;
  String? _lastActionMessage;

  List<SolverTask> _tasks = List<SolverTask>.unmodifiable(_seedTasks);

  SolverFeedFilter get filter => _filter;
  String? get lastActionMessage => _lastActionMessage;
  List<SolverTask> get tasks => _tasks;

  List<SolverTask> get visibleTasks {
    return _tasks.where((task) {
      switch (_filter) {
        case SolverFeedFilter.all:
          return true;
        case SolverFeedFilter.urgent:
          return task.isUrgent;
        case SolverFeedFilter.pending:
          return task.status == SolverTaskStatus.pending;
        case SolverFeedFilter.inProgress:
          return task.status == SolverTaskStatus.inProgress;
        case SolverFeedFilter.resolved:
          return task.status == SolverTaskStatus.resolved;
      }
    }).toList(growable: false);
  }

  int get allCount => _tasks.length;
  int get urgentCount => _tasks.where((t) => t.isUrgent).length;
  int get pendingCount =>
      _tasks.where((t) => t.status == SolverTaskStatus.pending).length;
  int get inProgressCount =>
      _tasks.where((t) => t.status == SolverTaskStatus.inProgress).length;
  int get resolvedCount =>
      _tasks.where((t) => t.status == SolverTaskStatus.resolved).length;

  int countFor(SolverFeedFilter filter) {
    switch (filter) {
      case SolverFeedFilter.all:
        return allCount;
      case SolverFeedFilter.urgent:
        return urgentCount;
      case SolverFeedFilter.pending:
        return pendingCount;
      case SolverFeedFilter.inProgress:
        return inProgressCount;
      case SolverFeedFilter.resolved:
        return resolvedCount;
    }
  }

  void setFilter(SolverFeedFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void markInProgress(String id) {
    _patch(
      id,
      (task) => task.copyWith(status: SolverTaskStatus.inProgress),
      message: 'Task marked in progress',
    );
  }

  void assignTeam(String id, {String team = 'Ward Rapid Response'}) {
    _patch(
      id,
      (task) => task.copyWith(
        status: SolverTaskStatus.inProgress,
        assignedTeam: team,
      ),
      message: '$team assigned',
    );
  }

  void resolveIssue(String id) {
    _patch(
      id,
      (task) => task.copyWith(status: SolverTaskStatus.resolved),
      message: 'Issue marked resolved',
    );
  }

  void clearActionMessage() {
    if (_lastActionMessage == null) return;
    _lastActionMessage = null;
    notifyListeners();
  }

  void _patch(
    String id,
    SolverTask Function(SolverTask) transform, {
    required String message,
  }) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    final next = List<SolverTask>.from(_tasks);
    next[index] = transform(next[index]);
    _tasks = List<SolverTask>.unmodifiable(next);
    _lastActionMessage = message;
    notifyListeners();
  }
}

const _seedTasks = <SolverTask>[
  SolverTask(
    id: 'rpt_001',
    title: 'Deep pothole causing accidents',
    location: 'Sector 4, Main St',
    timeAgo: '2h ago',
    upvoteCount: 14,
    aiSummary: 'High traffic impact • Multiple upvotes (14)',
    priority: SolverPriority.high,
    status: SolverTaskStatus.pending,
  ),
  SolverTask(
    id: 'rpt_005',
    title: 'Open manhole without barricade',
    location: 'Bus stand, Ward 3',
    timeAgo: '2d ago',
    upvoteCount: 33,
    aiSummary: 'Public safety risk • Multiple upvotes (33)',
    priority: SolverPriority.critical,
    status: SolverTaskStatus.pending,
  ),
  SolverTask(
    id: 'rpt_003',
    title: 'Overflowing drain after rainfall',
    location: 'Ward 12, Canal Road',
    timeAgo: '1d ago',
    upvoteCount: 21,
    aiSummary: 'Flooding likely after rain • Multiple upvotes (21)',
    priority: SolverPriority.medium,
    status: SolverTaskStatus.inProgress,
    assignedTeam: 'Drainage Unit B',
  ),
  SolverTask(
    id: 'rpt_002',
    title: 'Broken streetlight on main road',
    location: 'MG Road',
    timeAgo: '5h ago',
    upvoteCount: 9,
    aiSummary: 'Night visibility reduced • Multiple upvotes (9)',
    priority: SolverPriority.low,
    status: SolverTaskStatus.resolved,
  ),
  SolverTask(
    id: 'rpt_004',
    title: 'Garbage pile near community park',
    location: 'Sector 4, Park Gate',
    timeAgo: '1d ago',
    upvoteCount: 6,
    aiSummary: 'Sanitation backlog • Multiple upvotes (6)',
    priority: SolverPriority.medium,
    status: SolverTaskStatus.resolved,
  ),
];
