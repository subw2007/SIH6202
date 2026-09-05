import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../providers/report_form_provider.dart';

/// Dashed camera well: empty capture CTA or selected-image preview.
class MediaPickerBox extends StatelessWidget {
  const MediaPickerBox({
    super.key,
    required this.hasImage,
    this.imageBytes,
    required this.hint,
    required this.onPick,
    required this.onClear,
  });

  final bool hasImage;
  final Uint8List? imageBytes;
  final String hint;
  final ValueChanged<ImagePickSource> onPick;
  final VoidCallback onClear;

  static const boxHeight = 188.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: boxHeight,
          child: hasImage
              ? _Preview(
                  imageBytes: imageBytes,
                  onRetake: () => _chooseSource(context),
                )
              : _Empty(hint: hint, onTap: () => _chooseSource(context)),
        ),
        if (hasImage) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _chooseSource(context),
                  icon: const Icon(Icons.cameraswitch_outlined, size: 20),
                  label: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _chooseSource(BuildContext context) async {
    final source = await showModalBottomSheet<ImagePickSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF4A62AD)),
                  title: const Text('Take Photo'),
                  onTap: () => Navigator.pop(ctx, ImagePickSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF4A62AD)),
                  title: const Text('Upload Image'),
                  onTap: () => Navigator.pop(ctx, ImagePickSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source != null) onPick(source);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF1F8),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _DashBorderPainter(),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_camera_outlined, size: 48, color: Color(0xFF4A62AD)),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C2333),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.onRetake,
    this.imageBytes,
  });

  final VoidCallback onRetake;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageBytes != null && imageBytes!.isNotEmpty)
            Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          else
            Container(
              color: const Color(0xFFEEF1F8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4A62AD),
                ),
              ),
            ),
          Positioned(
            right: 10,
            top: 10,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onRetake,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Retake',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A62AD)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(20),
    );
    const dash = 8.0;
    const gap = 6.0;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = dist + dash;
        canvas.drawPath(metric.extractPath(dist, next.clamp(0, metric.length)), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

