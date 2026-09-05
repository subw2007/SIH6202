import 'package:flutter/material.dart';

import '../providers/solver_provider.dart';

const _kBlue = Color(0xFF4A62AD);
const _kInk = Color(0xFF1C2333);
const _kSecondary = Color(0xFF6B7280);

class JoinTeamView extends StatelessWidget {
  const JoinTeamView({required this.task, super.key});

  final SolverTask task;

  static const teams = [
    (
      name: 'Team CyberNode',
      college: 'IIT Delhi',
      members: 5,
      lead: 'Aarav Sharma',
    ),
    (name: 'EcoSolvers', college: 'DTU', members: 4, lead: 'Ananya Rao'),
    (
      name: 'Resilient Rural',
      college: 'NIT Surathkal',
      members: 6,
      lead: 'Vikram Singh',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Team')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            task.title,
            style: const TextStyle(
              color: _kInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose an active team working on this issue.',
            style: TextStyle(color: _kSecondary),
          ),
          const SizedBox(height: 20),
          ...teams.map(
            (team) => _TeamCard(
              team: team,
              onRequest: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request sent to ${team.name}.')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.onRequest});

  final ({String name, String college, int members, String lead}) team;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD9DEEA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${team.name} • ${team.college}',
              style: const TextStyle(
                color: _kInk,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text('${team.members} members  •  Lead: ${team.lead}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kBlue,
                  side: const BorderSide(color: _kBlue),
                ),
                child: const Text('Request to Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
