import 'dart:async';
import 'dart:ui';

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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final movies = widget.movies.take(5).toList();
      final next = (_current + 1) % movies.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            onPageChanged: (i) {
              setState(() => _current = i);
              _startTimer(); // reset timer on manual swipe
            },
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
                        : AppThemeColors.of(context)
                            .textMuted
                            .withValues(alpha: 0.5),
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
              errorWidget: (_, e, s) =>
                  Container(color: AppThemeColors.of(context).surface),
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
                    bg.withValues(alpha: 0.3),
                    bg.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.2, 0.55, 1.0],
                ),
              ),
            );
          }),

          // Blurred info box — full-width, anchored at bottom, poster + info
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: movie.hasPoster
                            ? CachedNetworkImage(
                                imageUrl: AppConstants.posterUrl(
                                    movie.posterPath!,
                                    size: AppConstants.posterW342),
                                width: 78,
                                height: 116,
                                fit: BoxFit.cover,
                                errorWidget: (_, e, s) => _buildPosterFallback(),
                              )
                            : _buildPosterFallback(),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.5)),
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
                            const SizedBox(height: 7),
                            Text(
                              movie.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                RatingBadge(rating: movie.voteAverage),
                                if (movie.year.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    movie.year,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _ActionButton(
                                  icon: Icons.play_arrow_rounded,
                                  label: 'Trailer',
                                  primary: true,
                                  onTap: () =>
                                      context.push('/movie/${movie.id}'),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  icon: Icons.info_outline_rounded,
                                  label: 'Details',
                                  primary: false,
                                  onTap: () =>
                                      context.push('/movie/${movie.id}'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterFallback() {
    return Container(
      width: 78,
      height: 116,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.movie_rounded, color: Colors.white54, size: 32),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primary
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: primary
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: primary ? Colors.black : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.black : Colors.white,
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
