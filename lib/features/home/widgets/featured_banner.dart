import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/rating_badge.dart';

class FeaturedBanner extends StatefulWidget {
  final List<Movie> movies;
  final ValueChanged<Movie>? onMovieChanged;

  const FeaturedBanner({super.key, required this.movies, this.onMovieChanged});

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
    // Notify parent of the initial movie
    final movies = widget.movies.take(5).toList();
    if (movies.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onMovieChanged?.call(movies[0]);
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final movies = widget.movies.take(5).toList();
      final next = (_current + 1) % movies.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
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
    if (movies.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 480,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: movies.length,
            onPageChanged: (i) {
              setState(() => _current = i);
              _startTimer();
              widget.onMovieChanged?.call(movies[i]);
            },
            itemBuilder: (ctx, i) => _BannerPage(movie: movies[i]),
          ),

          // Cinematic Indicators
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                movies.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _current == i ? 28 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: _current == i ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ] : null,
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

class _BannerPage extends ConsumerWidget {
  final Movie movie;

  const _BannerPage({required this.movie});

  Future<void> _launchTrailer(WidgetRef ref) async {
    final isTv = movie.mediaType == 'tv';
    final videos = await (isTv
        ? ref.read(tvVideosProvider(movie.id).future)
        : ref.read(movieVideosProvider(movie.id).future));

    final trailer = videos.firstWhere(
      (v) =>
          (v['type'] as String?)?.toLowerCase() == 'trailer' &&
          (v['site'] as String?) == 'YouTube',
      orElse: () => videos.firstWhere(
        (v) => (v['site'] as String?) == 'YouTube',
        orElse: () => {},
      ),
    );

    final key = trailer['key'] as String?;
    if (key == null) return;

    final uri = Uri.parse('https://www.youtube.com/watch?v=$key');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = AppThemeColors.of(context).background;

    return GestureDetector(
      onTap: () => context.push('/movie/${movie.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop
          Positioned.fill(
            child: movie.hasBackdrop
                ? CachedNetworkImage(
                    imageUrl: AppConstants.backdropUrl(movie.backdropPath!, size: AppConstants.backdropOriginal),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: (_, e, s) => Container(color: bg),
                  )
                : Container(color: bg),
          ),

          // Cinematic Overlay Gradients
          // 1. Top-down subtle shadow for status bar / app bar area
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Bottom-up heavy shadow for text legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    bg.withValues(alpha: 0.4),
                    bg.withValues(alpha: 0.95),
                    bg,
                  ],
                  stops: const [0.0, 0.4, 0.6, 0.85, 1.0],
                ),
              ),
            ),
          ),

          // Info Content
          Positioned(
            left: 24,
            right: 24,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glassmorphism Trending Tag
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'TRENDING NOW',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Title - Large & Impactful
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Metadata Row
                Row(
                  children: [
                    RatingBadge(rating: movie.voteAverage, fontSize: 13, iconSize: 15),
                  ],
                ),
                const SizedBox(height: 24),

                // Premium Action Buttons
                Row(
                  children: [
                    _CinematicButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Watch Trailer',
                      isPrimary: true,
                      onTap: () => _launchTrailer(ref),
                    ),
                    const SizedBox(width: 12),
                    _CinematicButton(
                      icon: Icons.info_outline_rounded,
                      label: 'Details',
                      isPrimary: false,
                      onTap: () {
                        final isTv = movie.mediaType == 'tv';
                        context.push(isTv ? '/tv/${movie.id}' : '/movie/${movie.id}');
                      },
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

class _CinematicButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _CinematicButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: isPrimary ? Colors.black : Colors.white),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: isPrimary
                ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                : ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
                border: isPrimary
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
