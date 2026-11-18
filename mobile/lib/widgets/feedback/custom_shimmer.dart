import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

/// Skeleton loader box with subtle dark shimmer effect.
class CustomShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const CustomShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surfaceBorder,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer placeholder list for loading cards.
class ZoneCardListSkeleton extends StatelessWidget {
  const ZoneCardListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 280,
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomShimmer(width: 120, height: 16),
                CustomShimmer(width: 60, height: 16),
              ],
            ),
            CustomShimmer(width: 180, height: 12),
            CustomShimmer(width: double.infinity, height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomShimmer(width: 80, height: 14),
                CustomShimmer(width: 50, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for the Home dashboard screen to prevent layout jumps.
class HomeDashboardSkeleton extends StatelessWidget {
  const HomeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomShimmer(width: 240, height: 36, borderRadius: 12),
          const SizedBox(height: 8),
          const CustomShimmer(width: 180, height: 18, borderRadius: 8),
          const SizedBox(height: 8),
          const CustomShimmer(width: 120, height: 14, borderRadius: 8),
          const SizedBox(height: 16),
          const CustomShimmer(
            width: double.infinity,
            height: 44,
            borderRadius: 16,
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomShimmer(width: 150, height: 22, borderRadius: 8),
              CustomShimmer(width: 90, height: 22, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomShimmer(width: 44, height: 44, borderRadius: 12),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomShimmer(width: 140, height: 16),
                              SizedBox(height: 8),
                              CustomShimmer(width: 90, height: 14),
                            ],
                          ),
                        ),
                        CustomShimmer(width: 64, height: 28, borderRadius: 8),
                      ],
                    ),
                    SizedBox(height: 12),
                    CustomShimmer(
                      width: double.infinity,
                      height: 6,
                      borderRadius: 4,
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

