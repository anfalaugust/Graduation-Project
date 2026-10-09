import 'package:flutter/material.dart';

import 'scan_page.dart';
import 'theme/app_colors.dart';
import 'widgets/app_bottom_nav.dart';
import 'History.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openScan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ScanPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bannerHeight = (screenWidth * 0.49).clamp(175.0, 205.0).toDouble();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              onNotificationsTap: () =>
                  _showMessage(context, "You're all caught up."),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroBanner(
                      height: bannerHeight,
                         onDiagnoseTap: () => _openScan(context),
                    ),
                    const SizedBox(height: 26),
                    const HomeScansSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(current: NavTab.home),
    );
  }
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key, required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Home',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.height,
    required this.onDiagnoseTap,
  });

  final double height;
  final VoidCallback onDiagnoseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/palm.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 12, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 0.62 * MediaQuery.sizeOf(context).width - 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Is your Date Palm\nlooking healthy?',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.12,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Scan or use images of your date\npalm to identify issues',
                      style: TextStyle(
                        color: Color(0xFFE8F0E9),
                        height: 1.5,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: FilledButton(
                        onPressed: onDiagnoseTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F2EF),
                          foregroundColor: AppColors.forest,
                          padding: const EdgeInsets.symmetric(horizontal: 19),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Diagnose Now!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 21,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    required this.isHealthy,
  });

  final String label;
  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? AppColors.leafGreen : AppColors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          height: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================================
// HOME: real data from Firestore (same source as History)
// ============================================================

class HomeScansSection extends StatefulWidget {
  const HomeScansSection({super.key});

  @override
  State<HomeScansSection> createState() => _HomeScansSectionState();
}

class _HomeScansSectionState extends State<HomeScansSection> {
  late final Stream<List<ScanRecord>> _stream =
      HistoryRepository().watchScans();

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Yesterday, $time';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScanRecord>>(
      stream: _stream,
      builder: (context, snapshot) {
        final scans = snapshot.data ?? const <ScanRecord>[];
        final healthy = scans.where((s) => s.isHealthy).length;
        final diseased = scans.length - healthy;

        Widget list;
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          list = const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          list = const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Could not load your scans.',
              style: TextStyle(color: AppColors.mutedText),
            ),
          );
        } else if (scans.isEmpty) {
          list = const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No scans yet. Tap "Diagnose Now!" to start.',
                style: TextStyle(color: AppColors.mutedText),
              ),
            ),
          );
        } else {
          list = Column(
            children: scans
                .take(4)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ScanCard(
                      record: r,
                      date: _formatDate(r.date),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ScanDetailsScreen(record: r),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    value: '$diseased',
                    label: 'Discovered Cases',
                    valueColor: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    value: '$healthy',
                    label: 'Healthy palms',
                    valueColor: AppColors.leafGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    value: '${scans.length}',
                    label: 'Total diagnosis',
                    valueColor: AppColors.forest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Last diagnosis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HistoryScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mutedText,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Show all', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            list,
          ],
        );
      },
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.record,
    required this.date,
    required this.onTap,
  });

  final ScanRecord record;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = record.isHealthy ? AppColors.leafGreen : AppColors.orange;
    final percent = record.confidence.round().clamp(0, 100);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                ScanImage(
                  url: record.imageUrl,
                  isHealthy: record.isHealthy,
                  width: 53,
                  height: 53,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              record.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFF202220),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          StatusTag(
                            label: record.isHealthy ? 'Healthy' : 'Diseased',
                            isHealthy: record.isHealthy,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          date,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent / 100,
                                minHeight: 4,
                                backgroundColor: AppColors.line,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              color: Color(0xFF292B29),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
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