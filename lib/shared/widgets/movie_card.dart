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
              // ── Poster ──────────────────────────────────────────────────
              movie.hasPoster
                  ? CachedNetworkImage(
                      imageUrl: AppConstants.posterUrl(movie.posterPath!),
                      fit: BoxFit.cover,
                      placeholder: (ctx, _) => _shimmerBox(ctx),
                      errorWidget: (ctx, _, _) => _posterFallback(ctx),
                    )
                  : _posterFallback(context),

              // ── Blurred info box ─────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
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
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.primary, size: 11),
                              const SizedBox(width: 2),
                              Text(
                                movie.ratingFormatted,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (movie.year.isNotEmpty) ...[
                                const SizedBox(width: 5),
                                Text(
                                  movie.year,
                                  style: const TextStyle(
                                    color: Color(0xAAFFFFFF),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
