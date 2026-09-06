import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/citizen_feed_provider.dart';
import '../services/api_service.dart';
import '../services/report_author.dart';
import 'report_problem_screen.dart';
import 'widgets/feed_filter_bar.dart';
import 'widgets/citizen_problem_card.dart';
import 'widgets/settings_bottom_sheet.dart';

const _kBannerBlue = Color(0xFF4A62AD);
const _kPageBg = Color(0xFFF4F6FB);
const _kInk = Color(0xFF1C2333);

class CitizenView extends StatefulWidget {
  const CitizenView({super.key});

  @override
  State<CitizenView> createState() => _CitizenViewState();
}

class _CitizenViewState extends State<CitizenView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CitizenFeedProvider>().fetchCitizenFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<CitizenFeedProvider>();

    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: feed.fetchCitizenFeed,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: const _CitizenHeader(),
                  ),
                  const SliverToBoxAdapter(child: _ReportBanner()),
                  SliverToBoxAdapter(
                    child: FeedFilterBar(
                      city: 'All',
                      category: 'All',
                      severity: 'All',
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      onChanged: (city, category, severity) =>
                          feed.fetchCitizenFeed(
                            city: city,
                            category: category,
                            severity: severity,
                          ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _FeedHeader(reportCount: feed.reports.length),
                  ),
                  _buildFeed(feed),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: _ReportProblemFab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed(CitizenFeedProvider feed) {
    if (feed.isLoading && feed.reports.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (feed.errorMessage != null && feed.reports.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(feed.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: feed.fetchCitizenFeed,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (feed.reports.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No reports in your area yet.')),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 108),
      sliver: SliverList.separated(
        itemCount: feed.reports.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) =>
            CitizenProblemCard(
              post: _postFromReport(feed.reports[index]),
              onDetailPopped: feed.fetchCitizenFeed,
            ),
      ),
    );
  }

  CitizenProblemPost _postFromReport(Map<String, dynamic> report) {
    final latitude = report['latitude'];
    final longitude = report['longitude'];
    final location =
        report['location_name']?.toString() ??
        (latitude != null && longitude != null
            ? '$latitude, $longitude'
            : 'Location unavailable');
    final createdAt = DateTime.tryParse(report['created_at']?.toString() ?? '');
    final timeAgo = createdAt == null ? 'Just now' : _timeAgo(createdAt);
    final durationMs = report['audio_duration_ms'] as num?;
    final seconds = durationMs == null ? 0 : (durationMs / 1000).round();
    final metadata = report['ai_metadata'];
    final priority = report['priority']?.toString();
    final category =
        report['category']?.toString() ??
        (metadata is Map ? metadata['category']?.toString() : null) ??
        'Report';
    final severity =
        report['severity']?.toString() ??
        (metadata is Map ? metadata['severity']?.toString() : null) ??
        priority ??
        'MEDIUM';
    return CitizenProblemPost(
      id:
          report['id']?.toString() ??
          'report-${createdAt?.millisecondsSinceEpoch ?? 0}',
      title: report['title']?.toString().trim().isNotEmpty == true
          ? report['title'].toString()
          : 'Untitled report',
      category: category,
      severity: severity,
      location: location,
      timeAgo: timeAgo,
      upvoteCount: 0,
      audioDuration:
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
      isVerified:
          priority == 'high' ||
          metadata is Map && metadata['severity'] == 'high',
      imageUrl: ApiService.resolveMediaUrl(report['image_url']?.toString()),
      audioUrl: ApiService.resolveMediaUrl(report['audio_url']?.toString()),
      videoUrl: ApiService.resolveMediaUrl(report['video_url']?.toString()),
      audioTranscript: report['audio_transcript']?.toString(),
      translatedText: report['translated_text']?.toString(),
      description: report['description']?.toString(),
      createdAt: createdAt,
        authorName: reportAuthorName(report),
      locationName: location,
      commentCount: report['comment_count'] is num
          ? (report['comment_count'] as num).toInt()
          : report['comments'] is List
          ? (report['comments'] as List).length
          : 0,
        bundledCount: report['bundled_reports_count'] is num
          ? (report['bundled_reports_count'] as num).toInt()
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
}

class _CitizenHeader extends StatelessWidget {
  const _CitizenHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFD7DEF2),
            child: Icon(Icons.person, color: _kBannerBlue, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.watch<AuthProvider>().currentUser?['name']
                          ?.toString()
                          .split(' ')
                          .first ??
                      'User',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Citizen Mode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => showSettingsBottomSheet(context),
            icon: const Icon(Icons.settings_outlined, color: _kInk, size: 26),
          ),
        ],
      ),
    );
  }
}

class _ReportBanner extends StatelessWidget {
  const _ReportBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Material(
        color: _kBannerBlue,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => openReportProblem(context),
          borderRadius: BorderRadius.circular(22),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report New Problem',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.mic_none_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '(Photo  •  Voice note)',
                      style: TextStyle(
                        color: Color(0xFFE4E9F8),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.reportCount});

  final int reportCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent in your area',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '$reportCount reports',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
      ],
    );
  }
}

class _ReportProblemFab extends StatelessWidget {
  const _ReportProblemFab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: _kBannerBlue,
        elevation: 4,
        shadowColor: const Color(0x664A62AD),
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: () => openReportProblem(context),
          borderRadius: BorderRadius.circular(32),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'Report Problem',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
