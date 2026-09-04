import 'package:flutter/material.dart';

import 'audio_player_pill.dart';

class CitizenProblemPost {
  const CitizenProblemPost({
    required this.id,
    required this.title,
    required this.location,
    required this.timeAgo,
    required this.upvoteCount,
    required this.audioDuration,
    required this.isVerified,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String location;
  final String timeAgo;
  final int upvoteCount;
  final String audioDuration;
  final bool isVerified;
  final String? imageUrl;

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
  });

  final CitizenProblemPost post;
  final VoidCallback? onUpvote;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F1B3D),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 168,
            child: post.imageUrl != null
                ? Image.network(post.imageUrl!, fit: BoxFit.cover)
                : const _PotholePlaceholder(),
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
                    AudioPlayerPill(durationLabel: post.audioDuration),
                    const Spacer(),
                    _UpvotePill(
                      count: post.upvoteCount,
                      onTap: onUpvote,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _UpvotePill extends StatelessWidget {
  const _UpvotePill({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F5FA),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 22,
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
