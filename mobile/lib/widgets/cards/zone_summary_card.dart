import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/parking_zone.dart';
import '../../utils/zone_name_helper.dart';
import 'glass_card.dart';

/// Compact zone card used in the horizontal carousel at the bottom of the map view.
class ZoneSummaryCard extends StatelessWidget {
  final ParkingZone zone;
  final bool isSelected;
  final bool isBestPick;
  final VoidCallback onTap;

  const ZoneSummaryCard({
    super.key,
    required this.zone,
    required this.isSelected,
    this.isBestPick = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final occupancyRate = zone.occupancyRate.clamp(0.0, 1.0);
    final occupancyColor = AppColors.forOccupancy(occupancyRate);
    final statusWord = AppColors.statusLabelForOccupancy(occupancyRate);
    final friendlyName = ZoneNameHelper.getFriendlyName(zone.zoneId, zone.name);
    final typeLabel = ZoneNameHelper.getZoneTypeLabel(zone.isStructured);
    final typeColor =
        zone.isStructured ? AppColors.structuredZone : AppColors.unstructuredZone;

    return SizedBox(
      width: 264,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        backgroundColor:
            isSelected ? AppColors.surfaceElevated : AppColors.glassBackground,
        borderColor: isSelected
            ? AppColors.primary
            : (isBestPick
                ? AppColors.occupancyLow.withValues(alpha: 0.65)
                : AppColors.surfaceBorder),
        borderWidth: isSelected ? 2.0 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    friendlyName,
                    style: AppTypography.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                if (isBestPick)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.occupancyLow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.occupancyLow.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Best pick',
                      style: AppTypography.badgeLabel.copyWith(
                        color: AppColors.occupancyLow,
                        fontSize: 10,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      typeLabel,
                      style: AppTypography.badgeLabel.copyWith(
                        color: typeColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${zone.availableSpots} free',
                  style: AppTypography.titleLarge.copyWith(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  statusWord,
                  style: TextStyle(
                    color: occupancyColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: occupancyRate,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${zone.parkedVehicles} of ${zone.totalCapacity} taken',
                      style: AppTypography.labelSmall,
                    ),
                    Text(
                      typeLabel,
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
