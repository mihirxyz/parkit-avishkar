import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/theme/app_colors.dart';
import '../../models/parking_zone.dart';
import '../../utils/zone_name_helper.dart';

/// Helper builder producing styled polygon and marker layers for flutter_map.
class ZoneMapLayers {
  const ZoneMapLayers._();

  static List<Polygon> buildPolygons({
    required List<ParkingZone> zones,
    required ParkingZone? selectedZone,
    required Function(ParkingZone) onZoneSelected,
  }) {
    return zones.map((zone) {
      final isSelected = selectedZone?.zoneId == zone.zoneId;
      final occupancyColor = AppColors.forOccupancy(zone.occupancyRate);

      return Polygon(
        points: zone.polygonPoints,
        color: occupancyColor.withAlpha(isSelected ? 105 : 60),
        borderColor: isSelected ? AppColors.primary : occupancyColor,
        borderStrokeWidth: isSelected ? 3.0 : 1.5,
      );
    }).toList();
  }

  static List<Marker> buildZoneLabels({
    required List<ParkingZone> zones,
    required ParkingZone? selectedZone,
    required String? bestZoneId,
    required Function(ParkingZone) onZoneSelected,
  }) {
    return zones.map((zone) {
      final isSelected = selectedZone?.zoneId == zone.zoneId;
      final isBestPick = bestZoneId != null && zone.zoneId == bestZoneId;
      final occupancyColor = AppColors.forOccupancy(zone.occupancyRate);
      final statusWord = AppColors.statusLabelForOccupancy(zone.occupancyRate);
      final shortName = ZoneNameHelper.getShortName(zone.zoneId, zone.name);

      return Marker(
        point: zone.center,
        width: 116,
        height: isBestPick ? 88 : 68,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onZoneSelected(zone),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surfaceElevated.withValues(alpha: 0.96)
                    : AppColors.surface.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isBestPick
                          ? AppColors.occupancyLow
                          : occupancyColor.withValues(alpha: 0.7)),
                  width: isSelected || isBestPick ? 1.8 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBestPick) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.occupancyLow.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Best pick',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.occupancyLow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      '${zone.availableSpots} free',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shortName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: occupancyColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusWord,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: occupancyColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
