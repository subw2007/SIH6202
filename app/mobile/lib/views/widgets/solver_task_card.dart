import 'package:flutter/material.dart';

import '../../providers/solver_provider.dart';
import 'priority_badge.dart';

const _kSurface = Color(0xFFFFFFFF);
const _kInk = Color(0xFF1C2333);
const _kSecondaryText = Color(0xFF6B7280);
const _kMutedMeta = Color(0xFF8A93A6);
const _kBannerBlue = Color(0xFF4A62AD);
const _kVerified = Color(0xFF4CAF50);
const _kVerifiedWash = Color(0xFFE8F5E9);
const _kHigh = Color(0xFFE53935);
const _kMedium = Color(0xFFFB8C00);

class SolverTaskCard extends StatelessWidget {
  const SolverTaskCard({
    required this.task,
    required this.onStatusChanged,
    required this.onViewDetails,
    required this.onJoinTeam,
    super.key,
  });

  final SolverTask task;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onViewDetails;
  final VoidCallback onJoinTeam;

  Color get _priorityColor => task.priority == TaskPriority.medium
      ? _kMedium
      : task.priority == TaskPriority.low
      ? _kVerified
      : _kHigh;

  IconData get _categoryIcon {
    switch (task.category) {
      case SolverCategory.infrastructure:
        return Icons.construction_outlined;
      case SolverCategory.water:
        return Icons.water_drop_outlined;
      case SolverCategory.electricity:
        return Icons.bolt_outlined;
      case SolverCategory.sanitation:
        return Icons.delete_outline;
      case SolverCategory.all:
        return Icons.category_outlined;
    }
  }

  String get _categoryLabel {
    switch (task.category) {
      case SolverCategory.infrastructure:
        return 'Infrastructure';
      case SolverCategory.water:
        return 'Water';
      case SolverCategory.electricity:
        return 'Electricity';
      case SolverCategory.sanitation:
        return 'Sanitation';
      case SolverCategory.all:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = task.status == TaskStatus.resolved;
    final statusColor = isResolved ? _kVerified : _kBannerBlue;
    final statusWash = isResolved ? _kVerifiedWash : const Color(0xFFE8EEFA);
    return Card(
      margin: EdgeInsets.zero,
      color: _kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _priorityColor.withValues(alpha: .42)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(color: _priorityColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PriorityBadge(priority: task.priority),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcon,
                                  size: 15,
                                  color: _kMutedMeta,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _categoryLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _kSecondaryText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        task.timestamp,
                        style: const TextStyle(
                          color: _kMutedMeta,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kSecondaryText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _Meta(icon: Icons.location_on_outlined, text: task.distance),
                _Meta(icon: Icons.keyboard_arrow_up, text: '${task.upvotes}'),
                _Meta(
                  icon: Icons.person_outline,
                  text: '${task.teamCount} on team',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatusPill(
                  label: isResolved ? 'Verified' : 'In Progress',
                  color: statusColor,
                  background: statusWash,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'View details',
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.visibility_outlined),
                  color: _kBannerBlue,
                  visualDensity: VisualDensity.compact,
                ),
                OutlinedButton(
                  onPressed: isResolved ? null : onJoinTeam,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: _kBannerBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Join Team'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: isResolved
                      ? null
                      : () => onStatusChanged(TaskStatus.inProgress),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kBannerBlue,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.build_outlined, size: 16),
                  label: Text(isResolved ? 'Done' : 'Work on This'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .24), const Color(0xFF6D7480)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.landscape_outlined,
        color: Colors.white.withValues(alpha: .9),
        size: 34,
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: _kMutedMeta),
      const SizedBox(width: 3),
      Text(
        text,
        style: const TextStyle(
          color: _kSecondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '• $label',
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
