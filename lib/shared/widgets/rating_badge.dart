import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  final double fontSize;
  final double iconSize;
  final bool showBackground;

  const RatingBadge({
    super.key,
    required this.rating,
    this.fontSize = 12,
    this.iconSize = 14,
    this.showBackground = true,
  });

  Color get _ratingColor {
    if (rating >= 7.5) return const Color(0xFF4CAF50);
    if (rating >= 6.0) return AppColors.primary;
    if (rating >= 4.0) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: showBackground
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : EdgeInsets.zero,
      decoration: showBackground
          ? BoxDecoration(
              color: _ratingColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _ratingColor.withValues(alpha: 0.3)),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: _ratingColor, size: iconSize),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: _ratingColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
