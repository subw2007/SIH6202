import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../views/widgets/audio_player_pill.dart';
import '../views/widgets/citizen_problem_card.dart';
import '../views/widgets/video_player_widget.dart';

class ProblemDetailScreen extends StatefulWidget {
  const ProblemDetailScreen({super.key, required this.post});

  final CitizenProblemPost post;

  @override
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  final _commentController = TextEditingController();
  final _apiService = ApiService();
  final _comments = <Map<String, dynamic>>[];
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;

  CitizenProblemPost get post => widget.post;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _apiService.fetchComments(post.id);
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(comments);
        _isLoadingComments = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _isSubmittingComment) return;
    final authProvider = context.read<AuthProvider>();
    setState(() => _isSubmittingComment = true);
    try {
      final savedComment = await _apiService.addComment(
        reportId: post.id,
        text: comment,
        authorName: authProvider.currentUser?['name']?.toString(),
      );
      if (!mounted) return;
      setState(() {
        _comments.add(savedComment);
        _commentController.clear();
        _isSubmittingComment = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmittingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save comment. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final audioUrl = ApiService.resolveMediaUrl(post.audioUrl);
    final location = post.locationName?.trim().isNotEmpty == true
        ? post.locationName!
        : post.location;
    final description = post.description?.trim() ?? '';
    final refinedDescription = post.translatedText?.trim().isNotEmpty == true
      ? post.translatedText!.trim()
      : description;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Problem details'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C2333),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFD7DEF2),
                child: Icon(Icons.person, color: Color(0xFF4A62AD)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _timestamp,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: post.videoUrl?.isNotEmpty == true
                ? VideoPlayerWidget(source: post.videoUrl!, height: 220)
                : SizedBox(
                    height: 220,
                    child: post.imageUrl?.isNotEmpty == true
                        ? Image.network(post.imageUrl!, fit: BoxFit.cover)
                        : const ColoredBox(
                            color: Color(0xFFDDE2EF),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Color(0xFF7D89A8),
                              ),
                            ),
                          ),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C2333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C2333),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFD9DEEA)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (refinedDescription.isNotEmpty)
                    const Chip(
                      avatar: Icon(Icons.auto_awesome_rounded, size: 16),
                      label: Text('✦ AI Refined'),
                    ),
                  Text(
                    refinedDescription.isNotEmpty
                        ? refinedDescription
                        : 'No description provided.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      color: Color(0xFF39445D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _LocationCard(address: location),
          if (audioUrl.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Voice note',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A62AD),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AudioPlayerPill(
                durationLabel: post.audioDuration,
                audioUrl: audioUrl,
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'Comments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C2333),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingComments)
            const Center(child: CircularProgressIndicator())
          else if (_comments.isEmpty)
            const Text(
              'No comments yet.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          else
            ..._comments.map(
              (comment) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 18),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['authorName']?.toString() ??
                          authProvider.currentUser?['name']?.toString() ??
                          'Anonymous User',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(comment['text']?.toString() ?? ''),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addComment(),
                  decoration: const InputDecoration(
                    hintText: 'Add a comment',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send comment',
                onPressed: _isSubmittingComment ? null : _addComment,
                icon: _isSubmittingComment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _timestamp {
    final createdAt = post.createdAt;
    if (createdAt == null) return post.timeAgo;
    return '${createdAt.toLocal()}'.split('.').first;
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9DEEA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Color(0xFF4A62AD)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF39445D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
