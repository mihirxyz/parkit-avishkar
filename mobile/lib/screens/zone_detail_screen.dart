import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/parking_zone.dart';
import '../providers/parking_provider.dart';
import '../utils/zone_name_helper.dart';
import '../widgets/cards/glass_card.dart';
import '../widgets/cards/metric_stat_card.dart';
import '../widgets/cards/reading_tile.dart';
import '../widgets/charts/occupancy_radial_gauge.dart';
import '../widgets/feedback/custom_shimmer.dart';

class ZoneDetailScreen extends StatefulWidget {
  final ParkingZone zone;
  const ZoneDetailScreen({super.key, required this.zone});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingProvider>().loadZoneDetail(widget.zone.zoneId);
    });
  }

  Future<void> _navigateToZone(ParkingZone zone) async {
    final launched = await ZoneNameHelper.openGoogleMaps(
      lat: zone.center.latitude,
      lon: zone.center.longitude,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps on this device.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParkingProvider>();
    final currentZone = (provider.selectedZone?.zoneId == widget.zone.zoneId)
        ? provider.selectedZone!
        : widget.zone;
    final friendlyName = ZoneNameHelper.getFriendlyName(
      currentZone.zoneId,
      currentZone.name,
    );
    final typeLabel = ZoneNameHelper.getZoneTypeLabel(currentZone.isStructured);
    final zoneTypeColor = currentZone.isStructured
        ? AppColors.structuredZone
        : AppColors.unstructuredZone;
    final statusColor = AppColors.forOccupancy(currentZone.occupancyRate);
    final statusWord = AppColors.statusLabelForOccupancy(
      currentZone.occupancyRate,
    );
    final statusDescription = AppColors.statusDescriptionForOccupancy(
      currentZone.occupancyRate,
    );
    final isBestPick = provider.bestZone?.zoneId == currentZone.zoneId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(friendlyName, style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => provider.loadZoneDetail(currentZone.zoneId),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadZoneDetail(currentZone.zoneId),
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isBestPick)
                    _buildBadge('Best pick', AppColors.occupancyLow),
                  _buildBadge(statusWord, statusColor),
                  _buildBadge(typeLabel, zoneTypeColor),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Row(
                  children: [
                    OccupancyRadialGauge(
                      occupancyRate: currentZone.occupancyRate,
                      parked: currentZone.parkedVehicles,
                      total: currentZone.totalCapacity,
                      size: 116,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentZone.availableSpots == 1
                                ? '1 spot available'
                                : '${currentZone.availableSpots} spots available',
                            style: AppTypography.titleLarge.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusDescription,
                            style: AppTypography.bodyMedium.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${currentZone.parkedVehicles} of ${currentZone.totalCapacity} spots currently taken',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToZone(currentZone),
                  icon: const Icon(Icons.directions_rounded, size: 20),
                  label: const Text('Navigate'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MetricStatCard(
                      title: 'Free spots',
                      value: '${currentZone.availableSpots}',
                      icon: Icons.check_circle_outline_rounded,
                      accentColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricStatCard(
                      title: 'Parked cars',
                      value: '${currentZone.parkedVehicles}',
                      icon: Icons.local_parking_rounded,
                      accentColor: AppColors.stateParked,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricStatCard(
                      title: 'Cars passing by',
                      value: '${currentZone.movingVehicles}',
                      icon: Icons.directions_car_rounded,
                      accentColor: AppColors.stateMoving,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricStatCard(
                      title: 'Total capacity',
                      value: '${currentZone.totalCapacity}',
                      icon: Icons.grid_view_rounded,
                      accentColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOccupancySparklineCard(currentZone, statusColor),
              const SizedBox(height: 24),
              Text('Recent activity', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              _buildRecentActivitySection(provider, currentZone),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.badgeLabel.copyWith(color: color),
      ),
    );
  }

  Widget _buildOccupancySparklineCard(ParkingZone zone, Color statusColor) {
    final spots = _buildSparklinePoints(zone);
    final maxY = zone.totalCapacity.toDouble().clamp(1.0, 100.0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Occupancy trend', style: AppTypography.titleMedium),
              Text(
                '${zone.availableSpots} free now',
                style: AppTypography.labelSmall.copyWith(color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Spots taken across recent updates in this area',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 88,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 2).clamp(1.0, 50.0),
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.surfaceBorder,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: statusColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isLast = index == spots.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 4.5 : 2.5,
                          color: statusColor,
                          strokeWidth: 1.5,
                          strokeColor: AppColors.background,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          statusColor.withValues(alpha: 0.28),
                          statusColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSparklinePoints(ParkingZone zone) {
    final readings = zone.recentReadings.reversed.toList();
    final cap = zone.totalCapacity.toDouble();
    final currentParked = zone.parkedVehicles.toDouble().clamp(0.0, cap);

    if (readings.length >= 2) {
      int running = (zone.parkedVehicles -
              readings.where((r) => r.isParked).length)
          .clamp(0, zone.totalCapacity);
      final pts = <FlSpot>[];
      for (int i = 0; i < readings.length; i++) {
        if (readings[i].isParked) {
          running = (running + 1).clamp(0, zone.totalCapacity);
        }
        pts.add(FlSpot(i.toDouble(), running.toDouble()));
      }
      pts[pts.length - 1] = FlSpot((pts.length - 1).toDouble(), currentParked);
      return pts;
    }

    return [
      FlSpot(0, (currentParked - 1).clamp(0.0, cap)),
      FlSpot(1, currentParked),
      FlSpot(2, (currentParked - 0.5).clamp(0.0, cap)),
      FlSpot(3, currentParked),
      FlSpot(4, currentParked),
    ];
  }

  Widget _buildRecentActivitySection(
    ParkingProvider provider,
    ParkingZone currentZone,
  ) {
    if (provider.isLoadingDetail && currentZone.recentReadings.isEmpty) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: CustomShimmer(
              width: double.infinity,
              height: 64,
              borderRadius: 16,
            ),
          ),
        ),
      );
    }

    if (provider.detailErrorMessage != null &&
        currentZone.recentReadings.isEmpty) {
      return GlassCard(
        borderColor: AppColors.occupancyHigh,
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.occupancyHigh,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Could not load recent activity for this area.',
                style: AppTypography.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => provider.loadZoneDetail(currentZone.zoneId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (currentZone.recentReadings.isEmpty) {
      return GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No recent car activity recorded in this area yet.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentZone.recentReadings.length,
      itemBuilder: (ctx, i) => ReadingTile(
        reading: currentZone.recentReadings[i],
      ),
    );
  }
}
