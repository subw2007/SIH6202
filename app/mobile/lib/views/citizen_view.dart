import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_mode_provider.dart';
import 'report_problem_screen.dart';
import 'widgets/citizen_problem_card.dart';
import 'widgets/settings_bottom_sheet.dart';

const _kBannerBlue = Color(0xFF4A62AD);
const _kPageBg = Color(0xFFF4F6FB);
const _kInk = Color(0xFF1C2333);

/// Mock local-area feed. Replace with FastAPI list endpoint in the next pass.
const citizenFeedMock = <CitizenProblemPost>[
  CitizenProblemPost(
    id: 'rpt_001',
    title: 'Deep pothole causing accidents',
    location: 'Location',
    timeAgo: '2h ago',
    upvoteCount: 14,
    audioDuration: '0:20',
    isVerified: true,
  ),
  CitizenProblemPost(
    id: 'rpt_002',
    title: 'Broken streetlight on main road',
    location: 'MG Road',
    timeAgo: '5h ago',
    upvoteCount: 9,
    audioDuration: '0:12',
    isVerified: true,
  ),
  CitizenProblemPost(
    id: 'rpt_003',
    title: 'Overflowing drain after rainfall',
    location: 'Ward 12',
    timeAgo: '1d ago',
    upvoteCount: 21,
    audioDuration: '0:31',
    isVerified: false,
  ),
  CitizenProblemPost(
    id: 'rpt_004',
    title: 'Garbage pile near community park',
    location: 'Sector 4',
    timeAgo: '1d ago',
    upvoteCount: 6,
    audioDuration: '0:08',
    isVerified: true,
  ),
  CitizenProblemPost(
    id: 'rpt_005',
    title: 'Open manhole without barricade',
    location: 'Bus stand',
    timeAgo: '2d ago',
    upvoteCount: 33,
    audioDuration: '0:18',
    isVerified: true,
  ),
];

class CitizenView extends StatelessWidget {
  const CitizenView({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<UserModeProvider>();

    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _CitizenHeader(username: mode.username),
                ),
                const SliverToBoxAdapter(child: _ReportBanner()),
                const SliverToBoxAdapter(child: _FeedHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 108),
                  sliver: SliverList.separated(
                    itemCount: citizenFeedMock.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return CitizenProblemCard(post: citizenFeedMock[index]);
                    },
                  ),
                ),
              ],
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
}

class _CitizenHeader extends StatelessWidget {
  const _CitizenHeader({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
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
                  username,
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
  const _FeedHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Recent in your area',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ),
          Text(
            '5 reports',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8A93A6),
            ),
          ),
        ],
      ),
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
        elevation: 8,
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
