import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/constants/api_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/parking_zone.dart';
import '../providers/parking_provider.dart';
import '../utils/zone_name_helper.dart';
import '../widgets/cards/glass_card.dart';
import '../widgets/cards/zone_summary_card.dart';
import '../widgets/feedback/custom_shimmer.dart';
import '../widgets/map/map_controls.dart';
import '../widgets/map/zone_polygon_layer.dart';
import 'zone_detail_screen.dart';

/// Consumer-grade zone map screen with plain-language grid cells, legend,
/// filter chips, and preview bottom sheet.
class ZoneMapScreen extends StatefulWidget {
  const ZoneMapScreen({super.key});

  @override
  State<ZoneMapScreen> createState() => _ZoneMapScreenState();
}

class _ZoneMapScreenState extends State<ZoneMapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ParkingProvider>();
      if (provider.zones.isEmpty && !provider.isLoading) {
        provider.fetchZones();
      }
    });
  }

  void _recenterMap() {
    _mapController.move(
      const LatLng(ApiConstants.puneCenterLat, ApiConstants.puneCenterLon),
      ApiConstants.defaultZoom,
    );
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 0.75);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 0.75);
  }

  void _handleMapTap(LatLng point, ParkingProvider provider) {
    for (final zone in provider.filteredZones) {
      if (point.latitude >= zone.latMin &&
          point.latitude <= zone.latMax &&
          point.longitude >= zone.lonMin &&
          point.longitude <= zone.lonMax) {
        _onZoneTapped(zone);
        return;
      }
    }
    provider.selectZone(null);
  }

  void _onZoneTapped(ParkingZone zone) {
    final provider = context.read<ParkingProvider>();
    provider.selectZone(zone);
    _mapController.move(zone.center, 17.2);

    final isBestPick = provider.bestFilteredZone?.zoneId == zone.zoneId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ZonePreviewBottomSheet(
        zone: zone,
        isBestPick: isBestPick,
        onSeeDetails: () {
          Navigator.pop(sheetCtx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ZoneDetailScreen(zone: zone)),
          );
        },
        onNavigate: () async {
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParkingProvider>();
    final bestZoneId = provider.bestFilteredZone?.zoneId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                ApiConstants.puneCenterLat,
                ApiConstants.puneCenterLon,
              ),
              initialZoom: ApiConstants.defaultZoom,
              minZoom: ApiConstants.minZoom,
              maxZoom: ApiConstants.maxZoom,
              onTap: (_, point) => _handleMapTap(point, provider),
            ),
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.35, 0, 0, 0, 0,
                  0, 0.35, 0, 0, 0,
                  0, 0, 0.40, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.parkit.mobile',
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              if (provider.filteredZones.isNotEmpty) ...[
                PolygonLayer(
                  polygons: ZoneMapLayers.buildPolygons(
                    zones: provider.filteredZones,
                    selectedZone: provider.selectedZone,
                    onZoneSelected: _onZoneTapped,
                  ),
                ),
                MarkerLayer(
                  markers: ZoneMapLayers.buildZoneLabels(
                    zones: provider.filteredZones,
                    selectedZone: provider.selectedZone,
                    bestZoneId: bestZoneId,
                    onZoneSelected: _onZoneTapped,
                  ),
                ),
              ],
            ],
          ),
          // Top Bar Header Overlay + Plain Filter Chips + Legend
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_parking_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pune Parking Map',
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              provider.isLoading && provider.zones.isEmpty
                                  ? 'Checking live parking spots...'
                                  : '${provider.totalAvailable} spots free across ${provider.zones.length} areas',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        tooltip: 'Refresh map',
                        onPressed: () => provider.fetchZones(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', provider),
                      const SizedBox(width: 8),
                      _buildFilterChip('Parking lots', 'structured', provider),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Street side',
                        'unstructured',
                        provider,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegendPill(),
              ],
            ),
          ),

          // Floating Map Controls
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 184,
            child: MapControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onRecenter: _recenterMap,
              onRefresh: () => provider.fetchZones(),
            ),
          ),

          // Bottom Zone Carousel
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.isLoading && provider.zones.isEmpty)
                  const SizedBox(height: 148, child: ZoneCardListSkeleton())
                else if (provider.hasError && provider.zones.isEmpty)
                  _buildMapErrorCard(provider)
                else if (provider.filteredZones.isEmpty)
                  _buildMapEmptyCard(provider)
                else
                  SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.filteredZones.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, index) {
                        final zone = provider.filteredZones[index];
                        final isSelected =
                            provider.selectedZone?.zoneId == zone.zoneId;
                        final isBestPick =
                            bestZoneId != null && zone.zoneId == bestZoneId;
                        return ZoneSummaryCard(
                          zone: zone,
                          isSelected: isSelected,
                          isBestPick: isBestPick,
                          onTap: () => _onZoneTapped(zone),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          _buildLegendItem(AppColors.occupancyLow, 'Plenty free'),
          _buildLegendItem(AppColors.occupancyMedium, 'Filling up'),
          _buildLegendItem(AppColors.occupancyHigh, 'Almost full'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMapErrorCard(ParkingProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderColor: AppColors.occupancyHigh,
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.occupancyHigh,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unable to load map areas. Check your connection.',
                style: AppTypography.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => provider.fetchZones(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapEmptyCard(ParkingProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Row(
          children: [
            const Icon(
              Icons.filter_alt_off_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No parking areas match this filter.',
                style: AppTypography.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => provider.setFilterType('all'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(44, 44),
              ),
              child: const Text('Show All'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type, ParkingProvider provider) {
    final isSelected = provider.filterType == type;
    return SizedBox(
      height: 44,
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setFilterType(type),
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        selectedColor: AppColors.primary.withAlpha(55),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
    );
  }
}

class _ZonePreviewBottomSheet extends StatelessWidget {
  final ParkingZone zone;
  final bool isBestPick;
  final VoidCallback onSeeDetails;
  final VoidCallback onNavigate;

  const _ZonePreviewBottomSheet({
    required this.zone,
    required this.isBestPick,
    required this.onSeeDetails,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final friendlyName = ZoneNameHelper.getFriendlyName(zone.zoneId, zone.name);
    final typeLabel = ZoneNameHelper.getZoneTypeLabel(zone.isStructured);
    final occupancyRate = zone.occupancyRate.clamp(0.0, 1.0);
    final statusColor = AppColors.forOccupancy(occupancyRate);
    final statusWord = AppColors.statusLabelForOccupancy(occupancyRate);
    final spotsLabel = zone.availableSpots == 1
        ? '1 spot free'
        : '${zone.availableSpots} spots free';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isBestPick)
                _buildPillBadge('Best pick', AppColors.occupancyLow),
              _buildPillBadge(statusWord, statusColor),
              _buildPillBadge(
                typeLabel,
                zone.isStructured
                    ? AppColors.structuredZone
                    : AppColors.unstructuredZone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  friendlyName,
                  style: AppTypography.displayMedium,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                spotsLabel,
                style: AppTypography.titleLarge.copyWith(
                  color: statusColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${zone.parkedVehicles} of ${zone.totalCapacity} spots currently taken',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: occupancyRate,
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSeeDetails,
                  child: const Text('See details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
}

