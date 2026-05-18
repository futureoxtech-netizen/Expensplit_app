import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A vertical stack of shimmer skeleton rows. Uses Column (not ListView) so
/// it can be safely nested inside another ListView/Column without producing
/// unbounded-height errors.
class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({super.key, this.height = 80, this.count = 5});

  final double height;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1C1C28) : const Color(0xFFEDEDF3);
    final highlight = isDark ? const Color(0xFF2A2A3D) : const Color(0xFFF6F6FA);

    final block = Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1200),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          block,
        ],
      ],
    );
  }
}
