import 'package:flutter/material.dart';

import '../../providers/solver_provider.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({required this.priority, super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.medium => const Color(0xFFFB8C00),
      TaskPriority.low => const Color(0xFF4CAF50),
      _ => const Color(0xFFE53935),
    };
    final label = priority == TaskPriority.medium ? 'MEDIUM' : 'HIGH';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '• $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
