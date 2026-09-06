import 'package:flutter/material.dart';

import '../providers/solver_provider.dart';
import '../services/api_service.dart';

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
  final _apiService = ApiService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    _collegeController.dispose();
    _leadController.dispose();
    _contactController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _apiService.createTeam(
        reportId: widget.task.id,
        name: _teamNameController.text.trim(),
        institution: _collegeController.text.trim(),
        leadName: _leadController.text.trim(),
        contact: _contactController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to create team. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
            _field(_collegeController, 'College / Institution Name'),
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
                child: _isSubmitting
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Team & Start Solver Mode'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
