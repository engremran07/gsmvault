import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';

class ArcticShimmer extends StatelessWidget {
  const ArcticShimmer({super.key, this.height = 80, this.count = 3});

  final double height;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cardColor =
        Theme.of(context).cardTheme.color ?? ArcticTheme.arcticCard;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: cardColor,
            highlightColor: surfaceColor,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
