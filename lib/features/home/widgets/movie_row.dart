import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/models/movie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../shared/widgets/section_header.dart';

class MovieRow extends StatelessWidget {
  final String title;
  final List<Movie>? movies;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Function(Movie)? onMovieTap;
  final double cardWidth;
  final double cardHeight;

  const MovieRow({
    super.key,
    required this.title,
    this.movies,
    this.isLoading = false,
    this.actionLabel,
    this.onActionTap,
    this.onMovieTap,
    this.cardWidth = 130,
    this.cardHeight = 195,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          actionLabel: actionLabel,
          onActionTap: onActionTap,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: cardHeight,
          child: isLoading
              ? _ShimmerRow(cardWidth: cardWidth, cardHeight: cardHeight)
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: movies?.length ?? 0,
                  itemBuilder: (ctx, i) {
                    final movie = movies![i];
                    return Padding(
                      padding: EdgeInsets.only(
                          right: i < (movies!.length - 1) ? 14 : 0),
                      child: MovieCard(
                        movie: movie,
                        width: cardWidth,
                        height: cardHeight,
                        onTap: () => onMovieTap?.call(movie),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;

  const _ShimmerRow({required this.cardWidth, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(right: i < 5 ? 14 : 0),
        child: Shimmer.fromColors(
          baseColor: colors.surfaceVariant,
          highlightColor: colors.card,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
