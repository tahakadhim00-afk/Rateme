import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/movie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/rating_badge.dart';

class FeaturedBanner extends StatefulWidget {
  final List<Movie> movies;

  const FeaturedBanner({super.key, required this.movies});

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movies = widget.movies.take(5).toList();
    return SizedBox(
      height: 440,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: movies.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) => _BannerPage(movie: movies[i]),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                movies.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? AppColors.primary
                        : AppThemeColors.of(context).textMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerPage extends StatelessWidget {
  final Movie movie;

  const _BannerPage({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movie/${movie.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop
          if (movie.hasBackdrop)
            CachedNetworkImage(
              imageUrl: AppConstants.backdropUrl(movie.backdropPath!),
              fit: BoxFit.cover,
              errorWidget: (_, e, s) => Container(color: AppThemeColors.of(context).surface),
            )
          else
            Container(color: AppThemeColors.of(context).surface),

          // Gradient overlay
          Builder(builder: (context) {
            final bg = AppThemeColors.of(context).background;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    bg.withValues(alpha: 0.5),
                    bg,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.2, 0.6, 1.0],
                ),
              ),
            );
          }),

          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'TRENDING',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  movie.title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        shadows: [
                          const Shadow(
                              blurRadius: 8, color: Colors.black45),
                        ],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    RatingBadge(rating: movie.voteAverage),
                    if (movie.year.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(movie.year,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Watch Trailer',
                      primary: true,
                      onTap: () => context.push('/movie/${movie.id}'),
                    ),
                    const SizedBox(width: 10),
                    _ActionButton(
                      icon: Icons.info_outline_rounded,
                      label: 'Details',
                      primary: false,
                      onTap: () => context.push('/movie/${movie.id}'),
                    ),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: primary
              ? null
              : Border.all(color: colors.border, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: primary ? Colors.black : colors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.black : colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
