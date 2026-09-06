import 'package:flutter/material.dart';

import '../../screens/problem_detail_screen.dart';
import 'video_player_widget.dart';

class CitizenProblemPost {
  const CitizenProblemPost({
    required this.id,
    required this.title,
    required this.location,
    required this.timeAgo,
    required this.upvoteCount,
    required this.audioDuration,
    required this.isVerified,
    this.category = 'Report',
    this.severity = 'MEDIUM',
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.audioTranscript,
    this.translatedText,
    this.description,
    this.createdAt,
    this.authorName = 'Citizen',
    this.locationName,
    this.commentCount = 0,
  });

  final String id;
  final String title;
  final String location;
  final String timeAgo;
  final int upvoteCount;
  final String audioDuration;
  final bool isVerified;
  final String category;
  final String severity;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String? audioTranscript;
  final String? translatedText;
  final String? description;
  final DateTime? createdAt;
  final String authorName;
  final String? locationName;
  final int commentCount;

  Map<String, dynamic> toMockJson() => {
    'id': id,
    'title': title,
    'location': location,
    'time_ago': timeAgo,
    'upvote_count': upvoteCount,
    'audio_duration': audioDuration,
    'is_verified': isVerified,
    'image_url': imageUrl,
  };
}

class CitizenProblemCard extends StatelessWidget {
  const CitizenProblemCard({
    super.key,
    required this.post,
    this.onUpvote,
    this.onDetailPopped,
  });

  final CitizenProblemPost post;
  final VoidCallback? onUpvote;
  final Future<void> Function()? onDetailPopped;

  Future<void> _openDetails(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProblemDetailScreen(post: post),
      ),
    );
    if (context.mounted) await onDetailPopped?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(context),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 168,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
                      VideoPlayerWidget(source: post.videoUrl!, height: 168)
                    else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                      Image.network(post.imageUrl!, fit: BoxFit.cover)
                    else
                      const _PotholePlaceholder(),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _OverlayPill(label: post.category),
                          const SizedBox(width: 6),
                          _OverlayPill(label: post.severity),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1C2333),
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${post.location}  ·  ${post.timeAgo}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (post.isVerified) const _VerifiedPill(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if ((post.audioUrl?.isNotEmpty ?? false) ||
                            (post.audioTranscript?.isNotEmpty ?? false))
                          const _VoiceNoteBadge(),
                        const Spacer(),
                        _CommentPill(count: post.commentCount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceNoteBadge extends StatelessWidget {
  const _VoiceNoteBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        '🔊 Voice Note',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A5568),
        ),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Verified',
        style: TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CommentPill extends StatelessWidget {
  const _CommentPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F5FA),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 18,
              color: Color(0xFF2D3A5F),
            ),
            const SizedBox(width: 2),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3A5F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PotholePlaceholder extends StatelessWidget {
  const _PotholePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF4A4F58),
      child: CustomPaint(
        painter: _PotholePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PotholePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final asphalt = Paint()..color = const Color(0xFF5A5F68);
    canvas.drawRect(Offset.zero & size, asphalt);

    final stripe = Paint()
      ..color = const Color(0xFFE8C547)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.square;
    const dash = 28.0;
    var x = 16.0;
    final y = size.height * 0.22;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + 18, y), stripe);
      x += dash;
    }

    final holeShadow = Paint()..color = const Color(0x66000000);
    final hole = Paint()..color = const Color(0xFF2A2D33);
    final rim = Paint()
      ..color = const Color(0xFF7A7F88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final oval = Rect.fromCenter(
      center: Offset(size.width * 0.52, size.height * 0.62),
      width: size.width * 0.46,
      height: size.height * 0.38,
    );
    canvas.drawOval(oval.shift(const Offset(4, 6)), holeShadow);
    canvas.drawOval(oval, hole);
    canvas.drawOval(oval, rim);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
