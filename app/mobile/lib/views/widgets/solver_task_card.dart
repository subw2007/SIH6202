import 'package:flutter/material.dart';

import '../../providers/solver_provider.dart';
import 'priority_badge.dart';

const _kInk = Color(0xFF1C2333);
const _kOfficialNavy = Color(0xFF1B3A6B);

class SolverTaskCard extends StatelessWidget {
  const SolverTaskCard({
    super.key,
    required this.task,
    required this.onMarkInProgress,
    required this.onAssignTeam,
    required this.onResolve,
    required this.onViewMap,
  });

  final SolverTask task;
  final VoidCallback onMarkInProgress;
  final VoidCallback onAssignTeam;
  final VoidCallback onResolve;
  final VoidCallback onViewMap;

  @override
  Widget build(BuildContext context) {
    final borderColor = priorityColor(task.priority);
    final isResolved = task.status == SolverTaskStatus.resolved;
    final isPending = task.status == SolverTaskStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F1B3D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: borderColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _kInk,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                task.timeAgo,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriorityBadge(priority: task.priority),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.location,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onViewMap,
                          style: TextButton.styleFrom(
                            foregroundColor: _kOfficialNavy,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'View on Map',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'AI Summary: ${task.aiSummary}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                    if (task.assignedTeam != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Assigned: ${task.assignedTeam}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kOfficialNavy,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isResolved
                                ? null
                                : (isPending ? onMarkInProgress : onAssignTeam),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kOfficialNavy,
                              side: BorderSide(
                                color: isResolved
                                    ? const Color(0xFFD9DEEA)
                                    : _kOfficialNavy,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isPending ? 'Mark In Progress' : 'Assign Team',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: isResolved ? null : onResolve,
                            style: FilledButton.styleFrom(
                              backgroundColor: _kOfficialNavy,
                              disabledBackgroundColor: const Color(0xFFB7C0D8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isResolved ? 'Resolved' : '✓ Resolve Issue',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
