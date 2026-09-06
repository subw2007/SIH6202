import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/citizen_feed_provider.dart';
import '../providers/report_form_provider.dart';
import '../screens/map_picker_screen.dart';
import '../screens/problem_detail_screen.dart';
import '../services/api_service.dart';
import 'widgets/citizen_problem_card.dart';
import 'widgets/media_picker_box.dart';
import 'widgets/video_picker_box.dart';
import 'widgets/voice_recorder_widget.dart';

const _kBlue = Color(0xFF4A62AD);
const _kInk = Color(0xFF1C2333);
const _kPage = Color(0xFFF4F6FB);

Future<void> openReportProblem(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ReportFormProvider(
          onReportSubmitted: context
              .read<CitizenFeedProvider>()
              .fetchCitizenFeed,
        )..startLocationDetection(),
        child: const ReportProblemScreen(),
      ),
    ),
  );
}

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _descriptionController = TextEditingController();
  Timer? _categorizationTimer;
  int _categorizationRequest = 0;
  int _summaryRequest = 0;
  String? _pendingSummary;

  void _scheduleCategorization(String description) {
    _categorizationTimer?.cancel();
    final trimmed = description.trim();
    if (trimmed.length <= 10) return;

    final requestId = ++_categorizationRequest;
    _categorizationTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final category = await _apiService.categorizeText(trimmed);
        if (!mounted || requestId != _categorizationRequest) return;
        context.read<ReportFormProvider>().setCategory(category);
      } catch (_) {}
    });
  }

  Future<void> _handleVoiceRecording(String audioPath) async {
    String transcript;
    try {
      transcript = (await _apiService.transcribeAudio(XFile(audioPath))).trim();
    } catch (_) {
      return;
    }
    if (transcript.isEmpty) return;
    if (!mounted) return;

    final form = context.read<ReportFormProvider>();
    _descriptionController.value = TextEditingValue(
      text: transcript,
      selection: TextSelection.collapsed(offset: transcript.length),
    );
    form.setTitle(transcript);

    try {
      await form.categorizeText(transcript);
    } catch (_) {}

    final requestId = ++_summaryRequest;
    try {
      final summary = await _apiService.summarizeText(transcript);
      if (!mounted || requestId != _summaryRequest) return;
      setState(() => _pendingSummary = summary);
    } catch (_) {}
  }

  void _applySummary() {
    final summary = _pendingSummary;
    if (summary == null || summary.trim().isEmpty) return;
    final refined = summary.trim();
    _descriptionController.value = TextEditingValue(
      text: refined,
      selection: TextSelection.collapsed(offset: refined.length),
    );
    context.read<ReportFormProvider>().setTitle(refined);
    setState(() => _pendingSummary = null);
    _scheduleCategorization(refined);
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ReportFormProvider>();
    final errorMessage = form.errorMessage;
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final message = form.consumeErrorMessage();
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      });
    }

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
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 28,
                      color: _kInk,
                    ),
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
                    imageFile: form.imageFile,
                    hint: form.imageHint,
                    onPick: form.pickImage,
                    onClear: form.clearImage,
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('Video'),
                  const SizedBox(height: 8),
                  VideoPickerBox(
                    videoFile: form.videoFile,
                    onPick: form.pickVideo,
                    onClear: form.clearVideo,
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('Voice note'),
                  const SizedBox(height: 16),
                  VoiceRecorderWidget(
                    onRecordingFinished: _handleVoiceRecording,
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('What is the issue?'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      form.setTitle(value);
                      _scheduleCategorization(value);
                    },
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What is the issue?',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                  if (_pendingSummary != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _applySummary,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text('Magic Refine'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: form.category,
                    onChanged: (value) {
                      if (value != null) form.setCategory(value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD9DEEA)),
                      ),
                    ),
                    items: ReportFormProvider.categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _openMapPicker(context, form),
                    child: _LocationPill(
                      label: form.locationLabel,
                      detecting:
                          form.locationState == LocationDetectState.detecting,
                      onChanged: form.setLocationLabel,
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: form.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
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

  @override
  void dispose() {
    _categorizationTimer?.cancel();
    _descriptionController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final form = context.read<ReportFormProvider>();
    final ok = await form.submit();
    if (!ok) {
      final conflictReportId = form.takeConflictReportId();
      if (conflictReportId != null && context.mounted) {
        final viewActiveReport = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Active Report Found'),
            content: const Text(
              'You already have an active report for this issue at this location.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('View Active Report'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
        if (viewActiveReport == true && context.mounted) {
          try {
            final report = await _apiService.fetchReport(conflictReportId);
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProblemDetailScreen(
                  post: _postFromReport(report),
                ),
              ),
            );
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to load the active report.')),
            );
          }
        }
      }
      return;
    }
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4CAF50),
                size: 64,
              ),
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

  CitizenProblemPost _postFromReport(Map<String, dynamic> report) {
    final latitude = report['latitude'];
    final longitude = report['longitude'];
    final location = report['location_name']?.toString() ??
        (latitude != null && longitude != null
            ? '$latitude, $longitude'
            : 'Location unavailable');
    final createdAt = DateTime.tryParse(report['created_at']?.toString() ?? '');
    final durationMs = report['audio_duration_ms'] as num?;
    final seconds = durationMs == null ? 0 : (durationMs / 1000).round();
    final metadata = report['ai_metadata'];
    final priority = report['priority']?.toString();
    return CitizenProblemPost(
      id: report['id']?.toString() ?? 'active-report',
      title: report['title']?.toString().trim().isNotEmpty == true
          ? report['title'].toString()
          : 'Untitled report',
      category: report['category']?.toString() ?? 'Report',
      severity: report['severity']?.toString() ?? priority ?? 'MEDIUM',
      location: location,
      timeAgo: createdAt == null ? 'Just now' : _timeAgo(createdAt),
      upvoteCount: 0,
      audioDuration:
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
      isVerified: priority == 'high' ||
          metadata is Map && metadata['severity'] == 'high',
      imageUrl: ApiService.resolveMediaUrl(report['image_url']?.toString()),
      audioUrl: ApiService.resolveMediaUrl(report['audio_url']?.toString()),
      videoUrl: ApiService.resolveMediaUrl(report['video_url']?.toString()),
      audioTranscript: report['audio_transcript']?.toString(),
      translatedText: report['translated_text']?.toString(),
      description: report['description']?.toString(),
      createdAt: createdAt,
      authorName: report['author_name']?.toString() ?? 'Citizen',
      locationName: location,
      commentCount: report['comment_count'] is num
          ? (report['comment_count'] as num).toInt()
          : 0,
    );
  }

  String _timeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  Future<void> _openMapPicker(
    BuildContext context,
    ReportFormProvider form,
  ) async {
    final result = await Navigator.of(context).push<MapPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialPoint: LatLng(
            form.latitude ?? 20.5937,
            form.longitude ?? 78.9629,
          ),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    form.setSelectedLocation(
      latitude: result.point.latitude,
      longitude: result.point.longitude,
      label: result.address,
    );
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
  const _LocationPill({
    required this.label,
    required this.detecting,
    required this.onChanged,
  });

  final String label;
  final bool detecting;
  final ValueChanged<String> onChanged;

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
            child: TextField(
              controller: TextEditingController(text: label),
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
              decoration: const InputDecoration.collapsed(
                hintText: 'Location name',
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
