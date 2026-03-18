import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A 360×640 (9:16) recommendation card — same resolution as RatingShareCard.
class RecommendShareCard extends StatelessWidget {
  final String title;
  final String year;
  final String? posterUrl;
  final String? username;

  const RecommendShareCard({
    super.key,
    required this.title,
    required this.year,
    required this.posterUrl,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
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
                    Color(0x55000000),
                    Color(0x00000000),
                    Color(0xCC000000),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.2, 0.55, 1.0],
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
                  // "RECOMMENDED" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.thumb_up_rounded,
                            color: Colors.white, size: 13),
                        SizedBox(width: 6),
                        Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
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

                  // "Must watch" tagline
                  const Text(
                    'You have to watch this!',
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 24),

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
