import 'package:flutter/material.dart';

/// Compact play chip: circular play control, static waveform bars, duration.
class AudioPlayerPill extends StatefulWidget {
  const AudioPlayerPill({
    super.key,
    required this.durationLabel,
    this.barCount = 18,
  });

  final String durationLabel;
  final int barCount;

  @override
  State<AudioPlayerPill> createState() => _AudioPlayerPillState();
}

class _AudioPlayerPillState extends State<AudioPlayerPill> {
  bool _playing = false;

  static const _heights = <double>[
    0.35,
    0.55,
    0.80,
    0.45,
    0.95,
    0.60,
    0.40,
    0.75,
    0.50,
    0.88,
    0.42,
    0.70,
    0.55,
    0.90,
    0.38,
    0.65,
    0.48,
    0.72,
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF1F8),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () => setState(() => _playing = !_playing),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A62AD),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 22,
                width: widget.barCount * 3.2,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    heights: _heights.take(widget.barCount).toList(),
                    active: _playing,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.durationLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.heights, required this.active});

  final List<double> heights;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? const Color(0xFF4A62AD) : const Color(0xFF9AA6C3)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    final gap = size.width / heights.length;
    for (var i = 0; i < heights.length; i++) {
      final x = gap * i + gap / 2;
      final barH = heights[i] * size.height;
      final y1 = (size.height - barH) / 2;
      canvas.drawLine(Offset(x, y1), Offset(x, y1 + barH), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.active != active || oldDelegate.heights != heights;
  }
}
