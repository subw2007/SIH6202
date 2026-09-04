import 'package:flutter/material.dart';

import '../providers/solver_provider.dart';
import '../providers/user_mode_provider.dart';
import 'widgets/solver_task_card.dart';

const _kPageBg = Color(0xFFF4F6FB);
const _kSurface = Color(0xFFFFFFFF);
const _kInk = Color(0xFF1C2333);
const _kSecondaryText = Color(0xFF6B7280);
const _kMutedMeta = Color(0xFF8A93A6);
const _kBannerBlue = Color(0xFF4A62AD);
const _kAvatarGreen = Color(0xFF4CAF50);

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
      appBar: AppBar(
        backgroundColor: _kSurface,
        foregroundColor: _kInk,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: _kAvatarGreen,
              child: Text(
                'CV',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priority Feed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Solver Mode',
                  style: TextStyle(
                    color: _kSecondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch to Citizen Space',
            onPressed: modeProvider.toggleMode,
            icon: const Icon(Icons.settings_outlined, size: 26),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: solverProvider,
        builder: (context, child) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildCategoryFilters(),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  '5 problems',
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
            ...solverProvider.visibleTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SolverTaskCard(
                  task: task,
                  onViewDetails: () => _showDetails(context, task),
                  onJoinTeam: () => _showJoinConfirmation(context, task),
                  onStatusChanged: (status) =>
                      solverProvider.updateStatus(task.id, status),
                ),
              ),
            ),
          ],
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

  Future<void> _showDetails(BuildContext context, SolverTask task) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Text('${task.location} • ${task.timestamp}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinConfirmation(BuildContext context, SolverTask task) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join response team?'),
        content: Text('Join the team working on "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Join Team'),
          ),
        ],
      ),
    );
  }
}
