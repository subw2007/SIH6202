import 'package:flutter/material.dart';

import '../providers/solver_provider.dart';

const _kBlue = Color(0xFF4A62AD);
const _kInk = Color(0xFF1C2333);

class CreateTeamView extends StatefulWidget {
  const CreateTeamView({required this.task, super.key});

  final SolverTask task;

  @override
  State<CreateTeamView> createState() => _CreateTeamViewState();
}

class _CreateTeamViewState extends State<CreateTeamView> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _leadController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void dispose() {
    _teamNameController.dispose();
    _collegeController.dispose();
    _leadController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Solver Team')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.task.title,
              style: const TextStyle(
                color: _kInk,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _field(_teamNameController, 'Team Name'),
            _field(
              _collegeController,
              'College / Institution Name',
              suggestions: const [
                'IIT Delhi',
                'NIT Surathkal',
                'Delhi University',
              ],
            ),
            _field(_leadController, 'Team Lead Name'),
            _field(
              _contactController,
              'Contact Number / Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kBlue,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Create Team & Start Solver Mode'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    List<String> suggestions = const [],
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: suggestions.isEmpty
              ? null
              : 'Suggestions: ${suggestions.join(', ')}',
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
