import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/parking_zone.dart';
import '../../utils/zone_name_helper.dart';
import 'glass_card.dart';

/// Consumer-grade card showing parking availability, occupancy bar,
/// and "Recommended" highlight on the Home screen.
class ParkingOptionCard extends StatelessWidget {
  final ParkingZone zone;
  final VoidCallback onTap;
  final bool isRecommended;

  const ParkingOptionCard({
    super.key,
    required this.zone,
    required this.onTap,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final friendlyName = ZoneNameHelper.getFriendlyName(zone.zoneId, zone.name);
    final zoneTypeLabel = ZoneNameHelper.getZoneTypeLabel(zone.isStructured);
    final available = zone.availableSpots;
    final occupancyRate = zone.occupancyRate.clamp(0.0, 1.0);
    final statusColor = AppColors.forOccupancy(occupancyRate);
    final statusText = AppColors.statusLabelForOccupancy(occupancyRate);
    final statusIcon = AppColors.iconForOccupancy(occupancyRate);

    return GlassCard(
      onTap: onTap,
      borderColor: isRecommended
          ? AppColors.primary.withValues(alpha: 0.7)
          : AppColors.surfaceBorder,
      borderWidth: isRecommended ? 1.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended) ...[
            _buildRecommendedBadge(zoneTypeLabel),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendlyName,
                      style: AppTypography.titleMedium.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildStatusBadge(statusText, statusColor),
                        if (!isRecommended)
                          Text(zoneTypeLabel, style: AppTypography.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$available free',
                    style: AppTypography.titleLarge.copyWith(
                      color: available > 0 ? AppColors.textPrimary : statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'of ${zone.totalCapacity} spots',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: occupancyRate,
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedBadge(String zoneTypeLabel) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Recommended',
                style: AppTypography.badgeLabel.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(zoneTypeLabel, style: AppTypography.labelSmall),
      ],
    );
  }

  Widget _buildStatusBadge(String statusText, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
