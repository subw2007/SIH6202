import 'package:flutter/material.dart';

import '../providers/solver_provider.dart';
import '../providers/user_mode_provider.dart';
import 'create_team_view.dart';
import 'join_team_view.dart';
import 'widgets/settings_bottom_sheet.dart';
import 'widgets/solver_task_card.dart';

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
    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: solverProvider,
          builder: (context, child) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _SolverHeader(username: modeProvider.username),
              const SizedBox(height: 12),
              _buildCategoryFilters(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '${solverProvider.tasks.length} problems',
                    style: TextStyle(color: _kMutedMeta, fontSize: 14),
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
                const Center(child: CircularProgressIndicator())
              else if (solverProvider.error != null && solverProvider.tasks.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Text(solverProvider.error!),
                      TextButton(
                        onPressed: solverProvider.fetchTasks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (solverProvider.visibleTasks.isEmpty)
                const Center(child: Text('No tasks found.'))
              else
                ...solverProvider.visibleTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SolverTaskCard(
                      task: task,
                      onJoinTeam: () => _openJoinTeam(context, task),
                      onWorkOnThis: () => _openCreateTeam(context, task),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      (SolverCategory.all, 'All', Icons.apps),
      (SolverCategory.infrastructure, 'Infrastructure', Icons.construction),
      (SolverCategory.water, 'Water', Icons.water_drop),
      (SolverCategory.electricity, 'Electricity', Icons.bolt),
      (SolverCategory.sanitation, 'Sanitation', Icons.delete_outline),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final selected = solverProvider.category == category.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                category.$3,
                size: 17,
                color: selected ? Colors.white : _kBannerBlue,
              ),
              label: Text(category.$2),
              selected: selected,
              selectedColor: _kBannerBlue,
              labelStyle: TextStyle(
                color: selected ? Colors.white : _kInk,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected ? _kBannerBlue : const Color(0xFFD9DEEA),
              ),
              onSelected: (_) => solverProvider.setCategory(category.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openJoinTeam(BuildContext context, SolverTask task) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => JoinTeamView(task: task)),
    );
  }

  Future<void> _openCreateTeam(BuildContext context, SolverTask task) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => CreateTeamView(task: task)),
    );
    if (created == true && context.mounted) {
      solverProvider.updateStatus(task.id, TaskStatus.inProgress);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team created. Solver Mode started.')),
      );
    }
  }
}

class _SolverHeader extends StatelessWidget {
  const _SolverHeader({required this.username});

  final String username;

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
                  username,
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
