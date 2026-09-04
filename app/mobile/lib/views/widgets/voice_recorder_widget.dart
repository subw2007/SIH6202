import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/report_form_provider.dart';

/// Large-target mic control with waveform + timer. Hold or tap to record.
class VoiceRecorderWidget extends StatefulWidget {
  const VoiceRecorderWidget({super.key});

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  void _syncWave(VoiceNotePhase phase) {
    if (phase == VoiceNotePhase.recording || phase == VoiceNotePhase.playing) {
      if (!_wave.isAnimating) _wave.repeat();
    } else if (_wave.isAnimating) {
      _wave.stop();
      _wave.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ReportFormProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncWave(form.voicePhase);
    });

    final recording = form.voicePhase == VoiceNotePhase.recording;
    final recorded = form.voicePhase == VoiceNotePhase.recorded ||
        form.voicePhase == VoiceNotePhase.playing;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (_held) return;
            if (form.voicePhase == VoiceNotePhase.recording) {
              form.stopRecording();
            } else if (form.voicePhase == VoiceNotePhase.idle) {
              form.startRecording();
            }
          },
          onLongPressStart: (_) {
            _held = true;
            if (form.voicePhase == VoiceNotePhase.idle) {
              form.startRecording();
            }
          },
          onLongPressEnd: (_) {
            form.stopRecording();
            Future<void>.delayed(const Duration(milliseconds: 80), () {
              if (mounted) _held = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: recording ? const Color(0xFFC62828) : const Color(0xFF4A62AD),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (recording ? const Color(0xFFC62828) : const Color(0xFF4A62AD))
                      .withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              recording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          recorded
              ? 'Voice note ready'
              : recording
                  ? 'Recording… tap or release to stop'
                  : 'Hold or Tap to Record Description',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C2333),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: recording || form.voicePhase == VoiceNotePhase.playing
              ? AnimatedBuilder(
                  animation: _wave,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(220, 36),
                      painter: _LiveWavePainter(t: _wave.value, hot: recording),
                    );
                  },
                )
              : CustomPaint(
                  size: const Size(220, 36),
                  painter: _LiveWavePainter(
                    t: recorded ? 0.2 : 0,
                    hot: false,
                    muted: !recorded,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          form.voiceTimerLabel,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Color(0xFF4A62AD),
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (recorded) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: form.togglePlayback,
                  icon: Icon(
                    form.voicePhase == VoiceNotePhase.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(form.voicePhase == VoiceNotePhase.playing ? 'Pause' : 'Play'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: form.reRecord,
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: const Text('Re-record'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Delete',
                onPressed: form.deleteRecording,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LiveWavePainter extends CustomPainter {
  _LiveWavePainter({
    required this.t,
    required this.hot,
    this.muted = false,
  });

  final double t;
  final bool hot;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = muted
          ? const Color(0xFFC5CCDA)
          : hot
              ? const Color(0xFFC62828)
              : const Color(0xFF4A62AD)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;

    const bars = 22;
    final gap = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final phase = (i / bars) + t;
      final wave = (1 + (i.isEven ? 1 : -1) * (0.35 + 0.65 * (0.5 + 0.5 * _sinApprox(phase * 6.28))))
          .clamp(0.2, 1.0);
      final h = muted ? size.height * 0.22 : size.height * (0.25 + 0.7 * wave);
      final x = gap * i + gap / 2;
      final y1 = (size.height - h) / 2;
      canvas.drawLine(Offset(x, y1), Offset(x, y1 + h), paint);
    }
  }

  double _sinApprox(double x) {
    final wrapped = (x % 6.2832) - 3.1416;
    final y = wrapped;
    return y - (y * y * y) / 6;
  }

  @override
  bool shouldRepaint(covariant _LiveWavePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.hot != hot || oldDelegate.muted != muted;
  }
}
