import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'glass_card.dart';

class HowParkItWorksCard extends StatelessWidget {
  final VoidCallback onHowItWorks;
  final VoidCallback onTryDemo;

  const HowParkItWorksCard({
    super.key,
    required this.onHowItWorks,
    required this.onTryDemo,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How ParkIt works', style: AppTypography.titleMedium),
          const SizedBox(height: 14),
          _Step('1', 'You park — your phone quietly notes it.'),
          const SizedBox(height: 12),
          _Step(
            '2',
            'Only the lesson is shared. Where you have been never leaves your phone.',
          ),
          const SizedBox(height: 12),
          _Step(
            '3',
            "Everyone's lessons combine, so the app predicts parking accurately.",
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onHowItWorks,
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('How does it work, exactly?'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: onTryDemo,
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerRight,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'See it happen — try the demo',
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTypography.bodyMedium)),
      ],
    );
  }
}
