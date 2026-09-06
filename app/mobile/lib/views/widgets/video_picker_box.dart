import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'video_player_widget.dart';

class VideoPickerBox extends StatelessWidget {
  const VideoPickerBox({
    required this.videoFile,
    required this.onPick,
    required this.onClear,
    super.key,
  });

  final XFile? videoFile;
  final Future<void> Function(ImageSource source) onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasVideo = videoFile != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: hasVideo
              ? VideoPlayerWidget(source: videoFile!.path)
              : Material(
                  color: const Color(0xFFEEF1F8),
                  child: InkWell(
                    onTap: () => _chooseSource(context),
                    child: const SizedBox(
                      height: 140,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_outlined, size: 42, color: Color(0xFF4A62AD)),
                          SizedBox(height: 8),
                          Text('Record or choose a video'),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        if (hasVideo) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _chooseSource(context),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline),
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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record Video'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose Video'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await onPick(source);
  }
}
