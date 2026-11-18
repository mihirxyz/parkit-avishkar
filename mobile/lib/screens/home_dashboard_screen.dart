import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/parking_provider.dart';
import '../widgets/cards/how_parkit_works_card.dart';
import '../widgets/cards/parking_option_card.dart';
import '../widgets/feedback/custom_shimmer.dart';
import 'fl_metrics_screen.dart';
import 'vehicle_simulator_sheet.dart';
import 'zone_detail_screen.dart';
import 'zone_map_screen.dart';

/// Friendly, non-technical home screen answering "where can I park?"
class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenMap;

  const HomeDashboardScreen({super.key, this.onOpenMap});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingProvider>().fetchZones();
    });
  }

  void _openZoneMap(BuildContext context) {
    if (widget.onOpenMap != null) {
      widget.onOpenMap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ZoneMapScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParkingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_parking_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text('ParkIt', style: AppTypography.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'About ParkIt',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchZones(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: provider.isLoading && provider.zones.isEmpty
            ? const HomeDashboardSkeleton()
            : provider.hasError && provider.zones.isEmpty
                ? _buildErrorState(provider)
                : provider.zones.isEmpty
                    ? _buildEmptyState(provider)
                    : _buildContent(context, provider),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ParkingProvider provider) {
    final totalAvailable = provider.totalAvailable;
    final zoneCount = provider.zones.length;
    final bestZoneId = provider.bestZone?.zoneId;

    final sortedZones = List.of(provider.zones)
      ..sort((a, b) {
        final byFree = b.availableSpots.compareTo(a.availableSpots);
        if (byFree != 0) return byFree;
        return a.occupancyRate.compareTo(b.occupancyRate);
      });

    final topZones = sortedZones.take(4).toList();

    return RefreshIndicator(
      onRefresh: () => provider.fetchZones(),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeadline(
              totalAvailable,
              zoneCount,
              provider.updatedTimestampLabel,
            ),
            const SizedBox(height: 16),
            _buildValuePropChip(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Best Options',
                  style: AppTypography.displayMedium.copyWith(fontSize: 20),
                ),
                TextButton.icon(
                  onPressed: () => _openZoneMap(context),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('View Map'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(44, 44),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...topZones.asMap().entries.map((entry) {
              final index = entry.key;
              final zone = entry.value;
              final isRecommended =
                  bestZoneId != null && zone.zoneId == bestZoneId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ParkingOptionCard(
                  zone: zone,
                  isRecommended: isRecommended,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZoneDetailScreen(zone: zone),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                      duration: const Duration(milliseconds: 250),
                      delay: Duration(milliseconds: 60 + index * 60),
                      curve: Curves.easeOutQuad,
                    )
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      duration: const Duration(milliseconds: 250),
                      delay: Duration(milliseconds: 60 + index * 60),
                      curve: Curves.easeOutQuad,
                    ),
              );
            }),
            const SizedBox(height: 16),
            HowParkItWorksCard(
              onHowItWorks: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FLMetricsScreen()),
              ),
              onTryDemo: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const VehicleSimulatorSheet(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openZoneMap(context),
                icon: const Icon(Icons.map_rounded),
                label: const Text('View Full Zone Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadline(
    int totalAvailable,
    int zoneCount,
    String updatedLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              totalAvailable > 0
                  ? Icons.check_circle_rounded
                  : Icons.warning_rounded,
              size: 38,
              color: totalAvailable > 0
                  ? AppColors.occupancyLow
                  : AppColors.occupancyMedium,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: totalAvailable > 0
                  ? TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: totalAvailable),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$value ',
                                style: AppTypography.displayLarge.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                              ),
                              TextSpan(
                                text: value == 1
                                    ? 'spot available now'
                                    : 'spots available now',
                                style: AppTypography.displayLarge.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Text(
                      'All zones currently full',
                      style: AppTypography.displayLarge.copyWith(fontSize: 26),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                totalAvailable > 0
                    ? 'across $zoneCount parking zones in Pune'
                    : 'Check back soon for availability',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.occupancyLow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    updatedLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValuePropChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Live now • Your location never leaves your phone',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ParkingProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_parking_rounded,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text('No parking areas available', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Pull down or tap below to check for live parking spots.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchZones(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ParkingProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.occupancyHigh,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load parking data',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchZones(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_parking_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text('About ParkIt', style: AppTypography.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ParkIt shows real-time parking availability using Federated Learning — a privacy-first AI approach.',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'How it works:',
              style: AppTypography.titleMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildInfoBullet('Vehicle sensors detect parking patterns locally'),
            _buildInfoBullet('Models train on your device, not in the cloud'),
            _buildInfoBullet(
              'Only model updates are shared, never raw location data',
            ),
            _buildInfoBullet(
              'Everyone benefits from collective learning without sacrificing privacy',
            ),
            const SizedBox(height: 12),
            Text(
              'Tap "How It Works" in the bottom nav to see technical details and model performance.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 7, right: 8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
