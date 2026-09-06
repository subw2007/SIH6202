import 'package:flutter/material.dart';

import '../providers/solver_provider.dart';
import '../services/api_service.dart';

const _kBlue = Color(0xFF4A62AD);
const _kInk = Color(0xFF1C2333);
const _kSecondary = Color(0xFF6B7280);

class JoinTeamView extends StatefulWidget {
  const JoinTeamView({required this.task, super.key});

  final SolverTask task;

  @override
  State<JoinTeamView> createState() => _JoinTeamViewState();
}

class _JoinTeamViewState extends State<JoinTeamView> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _apiService.fetchTeams(widget.task.id);
      if (mounted) setState(() => _teams = teams);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load teams.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Team')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.task.title,
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_teams.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No teams have been created for this issue yet.')),
            )
          else
            ..._teams.map(
              (team) => _TeamCard(
                team: team,
                onRequest: () => _joinTeam(team),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _joinTeam(Map<String, dynamic> team) async {
    try {
      await _apiService.joinTeam(team['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${team['name']}.')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to join team. Please try again.')),
        );
      }
    }
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.onRequest});

  final Map<String, dynamic> team;
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
              '${team['name']} • ${team['institution']}',
              style: const TextStyle(
                color: _kInk,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text('${team['member_count']} members  •  Lead: ${team['lead_name']}'),
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
