import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';

/// A 360×640 (9:16) card rendered at 3× pixelRatio = 1080×1920 —
/// Instagram Stories native resolution.
class RatingShareCard extends StatelessWidget {
  final String title;
  final String year;
  final String? posterUrl;

  /// Half-star scale 0.5–5.0.
  final double rating;

  /// Display name of the user sharing the card.
  final String? username;

  const RatingShareCard({
    super.key,
    required this.title,
    required this.year,
    required this.posterUrl,
    required this.rating,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    final scoreText = rating == rating.roundToDouble()
        ? '${rating.toInt()}'
        : rating.toStringAsFixed(1);
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;

    return SizedBox(
      width: 360,
      height: 640,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background poster ──────────────────────────────────────────
            if (posterUrl != null)
              CachedNetworkImage(imageUrl: posterUrl!, fit: BoxFit.cover)
            else
              const ColoredBox(color: Color(0xFF111118)),

            // ── Cinematic gradient overlay ─────────────────────────────────
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x44000000),
                    Color(0x00000000),
                    Color(0xBB000000),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.25, 0.58, 1.0],
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Positioned(
              left: 28,
              right: 28,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "MY RATING" badge
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text(
                        'MY RATING',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 14),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (year.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      year,
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Stars
                  Row(
                    children: List.generate(5, (i) {
                      final icon = i < fullStars
                          ? Icons.star_rounded
                          : (i == fullStars && hasHalf)
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded;
                      return Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Icon(icon, color: AppColors.primary, size: 36),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),

                  // Numeric score
                  Text(
                    '$scoreText / 5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Divider
                  const Divider(color: Color(0x33FFFFFF), thickness: 0.5),
                  const SizedBox(height: 14),

                  // RateMe branding + username
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/logo_and_images/app_bar.png',
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'RateMe',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      if (username != null && username!.isNotEmpty)
                        Text(
                          '@$username',
                          style: const TextStyle(
                            color: Color(0xAAFFFFFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
