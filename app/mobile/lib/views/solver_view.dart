import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/solver_provider.dart';
import '../providers/user_mode_provider.dart';
import '../providers/teams_provider.dart';
import 'create_team_view.dart';
import 'join_team_view.dart';
import 'widgets/settings_bottom_sheet.dart';
import 'widgets/solver_task_card.dart';
import 'widgets/feed_filter_bar.dart';

const _kPageBg = Color(0xFFF4F6FB);
const _kSurface = Color(0xFFFFFFFF);
const _kInk = Color(0xFF1C2333);
const _kSecondaryText = Color(0xFF6B7280);
const _kMutedMeta = Color(0xFF8A93A6);
const _kBannerBlue = Color(0xFF4A62AD);

class SolverView extends StatelessWidget {
  const SolverView({
    required this.modeProvider,
    required this.solverProvider,
    super.key,
  });

  final UserModeProvider modeProvider;
  final SolverProvider solverProvider;

  @override
  Widget build(BuildContext context) {
    final teamsProvider = context.watch<TeamsProvider>();
    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: solverProvider,
          builder: (context, child) => RefreshIndicator(
            onRefresh: solverProvider.fetchTasks,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const _SolverHeader(),
                const SizedBox(height: 12),
                FeedFilterBar(
                  city: 'All',
                  category: 'All',
                  severity: 'All',
                  onChanged: (city, category, severity) =>
                      solverProvider.fetchTasks(
                        city: city,
                        category: category,
                        severity: severity,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      '${solverProvider.tasks.length} problems',
                      style: const TextStyle(color: _kMutedMeta, fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE9E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '• ${solverProvider.highPriorityCount} high priority',
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (solverProvider.isLoading && solverProvider.tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (solverProvider.errorMessage != null &&
                    solverProvider.tasks.isEmpty)
                  _SolverError(
                    message: solverProvider.errorMessage!,
                    onRetry: solverProvider.fetchTasks,
                  )
                else if (solverProvider.visibleTasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('No solver tasks found.')),
                  )
                else
                  ...solverProvider.visibleTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SolverTaskCard(
                        task: task,
                        onDetailPopped: solverProvider.fetchTasks,
                        isUpdating: solverProvider.isUpdating(task.id),
                        joinedTeamName: teamsProvider.membershipForReport(task.id)?.name,
                        onJoinTeam: () => _openJoinTeam(context, task),
                        onWorkOnThis: () => _openCreateTeam(context, task),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openJoinTeam(BuildContext context, SolverTask task) async {
    final joined = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => JoinTeamView(task: task)),
    );
    if (joined == true && context.mounted) {
      await context.read<TeamsProvider>().refresh();
    }
  }

  Future<void> _openCreateTeam(BuildContext context, SolverTask task) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => CreateTeamView(task: task)),
    );
    if (created == true && context.mounted) {
      await context.read<TeamsProvider>().refresh();
      await solverProvider.fetchTasks();
      final updated = await solverProvider.updateStatus(
        task.id,
        TaskStatus.inProgress,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated
                ? 'Team created. Solver Mode started.'
                : 'Task status could not be updated.',
          ),
        ),
      );
    }
  }
}

class _SolverError extends StatelessWidget {
  const _SolverError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SolverHeader extends StatelessWidget {
  const _SolverHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFD7DEF2),
            child: Icon(Icons.person, color: _kBannerBlue, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.watch<AuthProvider>().currentUser?['name']
                          ?.toString()
                          .split(' ')
                          .first ??
                      'User',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Solver Mode',
                  style: TextStyle(
                    color: _kSecondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => showSettingsBottomSheet(context),
            icon: const Icon(Icons.settings_outlined, color: _kInk, size: 26),
          ),
        ],
      ),
    );
  }
}
