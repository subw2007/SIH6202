import 'package:flutter/material.dart';

import '../../providers/solver_provider.dart';

const kPriorityCritical = Color(0xFFE53935);
const kPriorityWarning = Color(0xFFFB8C00);
const kPriorityLow = Color(0xFF4CAF50);

Color priorityColor(SolverPriority priority) {
  switch (priority) {
    case SolverPriority.critical:
    case SolverPriority.high:
      return kPriorityCritical;
    case SolverPriority.medium:
      return kPriorityWarning;
    case SolverPriority.low:
      return kPriorityLow;
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final SolverPriority priority;

  Color get color => priorityColor(priority);

  String get label {
    switch (priority) {
      case SolverPriority.critical:
        return 'CRITICAL';
      case SolverPriority.high:
        return 'HIGH PRIORITY';
      case SolverPriority.medium:
        return 'MEDIUM';
      case SolverPriority.low:
        return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
