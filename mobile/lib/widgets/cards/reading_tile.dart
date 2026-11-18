import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/vehicle_reading.dart';

/// Clean, plain-language activity tile rendering a recent car update.
class ReadingTile extends StatelessWidget {
  final VehicleReading reading;

  const ReadingTile({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final isParked = reading.isParked;
    final stateColor = isParked ? AppColors.stateParked : AppColors.stateMoving;
    final timeFormatted = DateFormat('HH:mm:ss').format(reading.timestamp);
    final headline = isParked ? 'Parked car detected' : 'Passing car detected';
    final subLabel = isParked ? 'Spot taken' : 'Driving through';

    String? speedLabel;
    if (reading.gpsSpeed != null) {
      final kmh = (reading.gpsSpeed! * 3.6).round();
      speedLabel = kmh <= 1 ? 'Stopped' : '$kmh km/h';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: stateColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isParked
                  ? Icons.local_parking_rounded
                  : Icons.directions_car_rounded,
              color: stateColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      headline,
                      style: AppTypography.titleMedium.copyWith(fontSize: 14),
                    ),
                    Text(
                      timeFormatted,
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      subLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stateColor,
                      ),
                    ),
                    if (speedLabel != null) ...[
                      const Spacer(),
                      Text(
                        speedLabel,
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
