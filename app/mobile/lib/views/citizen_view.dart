import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/report_form_provider.dart';
import '../providers/user_mode_provider.dart';
import 'report_problem_screen.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<UserModeProvider>();
    final reportProvider = context.watch<ReportFormProvider>();

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
                  sliver: _buildFeed(reportProvider),
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

  Widget _buildFeed(ReportFormProvider provider) {
    if (provider.isFetchingReports && provider.citizenReports.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.feedError != null && provider.citizenReports.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            children: [
              Text(provider.feedError!),
              TextButton(
                onPressed: provider.fetchCitizenReports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.citizenReports.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text('No reports yet.')),
      );
    }
    return SliverList.separated(
      itemCount: provider.citizenReports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return CitizenProblemCard(post: provider.citizenReports[index]);
      },
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
