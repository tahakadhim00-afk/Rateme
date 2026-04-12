import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/movie.dart';
import '../../../core/theme/app_theme.dart';

class FeaturedBanner extends StatefulWidget {
  final List<Movie> movies;
  final ValueChanged<Movie>? onMovieChanged;

  const FeaturedBanner({super.key, required this.movies, this.onMovieChanged});

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  late final PageController _controller;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final movies = widget.movies.take(5).toList();
    final mid = movies.length ~/ 2;
    _current = mid;
    _controller = PageController(viewportFraction: 0.62, initialPage: mid);
    _startTimer();
    if (movies.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onMovieChanged?.call(movies[mid]);
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
        duration: const Duration(milliseconds: 700),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card Carousel
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.62;
            final cardHeight = cardWidth * 1.5; // 2:3 poster ratio
            return SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _controller,
                itemCount: movies.length,
                onPageChanged: (i) {
                  setState(() => _current = i);
                  _startTimer();
                  widget.onMovieChanged?.call(movies[i]);
                },
                itemBuilder: (ctx, i) {
                  final isActive = i == _current;
                  return AnimatedScale(
                    scale: isActive ? 1.0 : 0.93,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: _BannerCard(movie: movies[i]),
                  );
                },
              ),
            );
          },
        ),

        // Pagination dots — below the carousel
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(movies.length, (i) {
            final active = i == _current;
            return GestureDetector(
              onTap: () => _controller.animateToPage(
                i,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 10 : 7,
                height: active ? 10 : 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BannerCard extends ConsumerWidget {
  final Movie movie;

  const _BannerCard({required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = AppThemeColors.of(context).background;

    return GestureDetector(
      onTap: () {
        final isTv = movie.mediaType == 'tv';
        context.push(isTv ? '/tv/${movie.id}' : '/movie/${movie.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster image at original resolution
              movie.hasPoster
                  ? CachedNetworkImage(
                      imageUrl: AppConstants.posterUrl(
                        movie.posterPath!,
                        size: AppConstants.posterOriginal,
                      ),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorWidget: (_, e, s) => Container(color: bg),
                    )
                  : Container(color: bg),

              // Bottom gradient for title legibility
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // Title + rating at bottom
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (movie.voteAverage > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.primary, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            movie.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
