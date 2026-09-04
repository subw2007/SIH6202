import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/report_form_provider.dart';
import 'widgets/media_picker_box.dart';
import 'widgets/voice_recorder_widget.dart';

const _kBlue = Color(0xFF4A62AD);
const _kInk = Color(0xFF1C2333);
const _kPage = Color(0xFFF4F6FB);

Future<void> openReportProblem(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ReportFormProvider()..startLocationDetection(),
        child: const ReportProblemScreen(),
      ),
    ),
  );
}

class ReportProblemScreen extends StatelessWidget {
  const ReportProblemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ReportFormProvider>();

    return Scaffold(
      backgroundColor: _kPage,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'Report a Problem',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kInk,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 28, color: _kInk),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const _SectionLabel('Photo'),
                  const SizedBox(height: 8),
                  MediaPickerBox(
                    hasImage: form.hasImage,
                    hint: form.imageHint,
                    onPick: form.pickImage,
                    onClear: form.clearImage,
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('Voice note'),
                  const SizedBox(height: 16),
                  const VoiceRecorderWidget(),
                  const SizedBox(height: 28),
                  const _SectionLabel('What is the issue?'),
                  const SizedBox(height: 8),
                  TextField(
                    textInputAction: TextInputAction.done,
                    onChanged: form.setTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'What is the issue?',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9DEEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9DEEA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kBlue, width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LocationPill(
                    label: form.locationLabel,
                    detecting: form.locationState == LocationDetectState.detecting,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: form.canSubmit ? () => _submit(context) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kBlue,
                    disabledBackgroundColor: const Color(0xFFB7C0D8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  child: form.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('🚀 Submit Report'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final form = context.read<ReportFormProvider>();
    final ok = await form.submit();
    if (!ok || !context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 64),
              SizedBox(height: 16),
              Text(
                'Report Submitted Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(backgroundColor: _kBlue),
              child: const Text('Back to feed'),
            ),
          ],
        );
      },
    );

    if (context.mounted) Navigator.of(context).pop();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4A5568),
        letterSpacing: 0.2,
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label, required this.detecting});

  final String label;
  final bool detecting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD9DEEA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: _kBlue, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
            ),
          ),
          if (detecting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
            )
          else
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
        ],
      ),
    );
  }
}
