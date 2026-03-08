import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/movie.dart';
import '../../core/theme/app_theme.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.width = 130,
    this.height = 195,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Poster Image ──────────────────────────────────────────
              movie.hasPoster
                  ? CachedNetworkImage(
                      imageUrl: AppConstants.posterUrl(movie.posterPath!),
                      fit: BoxFit.cover,
                      placeholder: (ctx, _) => _shimmerBox(ctx),
                      errorWidget: (ctx, _, _) => _posterFallback(ctx),
                    )
                  : _posterFallback(context),

              // ── 2. Maximum Cinematic Radial Blur ─────────────────────────
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 2.0, // Expanded radius to cover more ground
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.25, 1.0], // Pushes extreme blur density
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), // Extreme blur level
                      child: Container(
                        // Heavy opacity for maximum "frosted" impact
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. Sharp Text Layer (Unmasked) ───────────────────────────
              Positioned(
                left: 12,
                bottom: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900, 
                        height: 1.1,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.primary, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          movie.ratingFormatted,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (movie.year.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            movie.year,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _shimmerBox(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: colors.card,
      child: Container(color: colors.surfaceVariant),
    );
  }

  Widget _posterFallback(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      color: colors.surfaceVariant,
      child: Center(
        child: Icon(Icons.movie_outlined, color: colors.textMuted, size: 40),
      ),
    );
  }
}
