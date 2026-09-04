import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/solver_provider.dart';
import 'citizen_view.dart';
import 'widgets/solver_task_card.dart';

const _kPageBg = Color(0xFFF4F6FB);
const _kInk = Color(0xFF1C2333);
const _kOfficialNavy = Color(0xFF1B3A6B);

class SolverView extends StatelessWidget {
  const SolverView({super.key});

  @override
  Widget build(BuildContext context) {
    final solver = context.watch<SolverProvider>();

    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _SolverHeader()),
            SliverToBoxAdapter(child: _FilterBar(solver: solver)),
            SliverToBoxAdapter(child: _AnalyticsRow(solver: solver)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              sliver: solver.visibleTasks.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyInbox())
                  : SliverList.separated(
                      itemCount: solver.visibleTasks.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final task = solver.visibleTasks[index];
                        return SolverTaskCard(
                          task: task,
                          onMarkInProgress: () => solver.markInProgress(task.id),
                          onAssignTeam: () => solver.assignTeam(task.id),
                          onResolve: () => _confirmResolve(context, task),
                          onViewMap: () => _showMapSnack(context, task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolverHeader extends StatelessWidget {
  const _SolverHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFD7DEF2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: _kOfficialNavy,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solver Workspace',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Official Mode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => showModeToggleSheet(context),
            icon: const Icon(Icons.settings_outlined, color: _kInk, size: 26),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.solver});

  final SolverProvider solver;

  static const _pills = <(SolverFeedFilter, String)>[
    (SolverFeedFilter.all, 'All'),
    (SolverFeedFilter.urgent, 'Urgent'),
    (SolverFeedFilter.inProgress, 'In Progress'),
    (SolverFeedFilter.resolved, 'Resolved'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        scrollDirection: Axis.horizontal,
        itemCount: _pills.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = _pills[index];
          final selected = solver.filter == filter;
          final count = solver.countFor(filter);
          return ChoiceChip(
            label: Text('$label ($count)'),
            selected: selected,
            onSelected: (_) => solver.setFilter(filter),
            showCheckmark: false,
            selectedColor: _kOfficialNavy,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _kInk,
            ),
            side: BorderSide(
              color: selected ? _kOfficialNavy : const Color(0xFFD9DEEA),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({required this.solver});

  final SolverProvider solver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          _StatCard(
            label: 'Pending',
            count: solver.pendingCount,
            accent: const Color(0xFFFB8C00),
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'In Progress',
            count: solver.inProgressCount,
            accent: _kOfficialNavy,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Resolved',
            count: solver.resolvedCount,
            accent: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.accent,
  });

  final String label;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F1B3D),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'No tasks in this filter.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmResolve(BuildContext context, SolverTask task) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Resolve issue?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Mark “${task.title}” as resolved? This updates the official inbox status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _kOfficialNavy),
            child: const Text('Resolve'),
          ),
        ],
      );
    },
  );

  if (confirmed == true && context.mounted) {
    context.read<SolverProvider>().resolveIssue(task.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Issue marked resolved')),
    );
  }
}

void _showMapSnack(BuildContext context, SolverTask task) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Map preview: ${task.location}')),
  );
}
