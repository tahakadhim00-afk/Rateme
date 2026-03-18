import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/genre.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../shared/widgets/section_header.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final selectedGenre = ref.watch(selectedGenreProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Builder(builder: (context) {
                final colors = AppThemeColors.of(context);
                return TextField(
                  controller: _controller,
                  style: TextStyle(color: colors.textPrimary),
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Search movies, actors, directors',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: colors.textMuted),
                    suffixIcon: _controller.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _controller.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                            child: Icon(Icons.close_rounded,
                                color: colors.textMuted),
                          )
                        : null,
                  ),
                );
              }),
            ),

            // Content
            Expanded(
              child: query.trim().isEmpty
                  ? _BrowseView(selectedGenre: selectedGenre)
                  : results.when(
                      data: (movies) => movies.isEmpty
                          ? _EmptyResults(query: query)
                          : _SearchResults(movies: movies),
                      loading: () => const _ShimmerGrid(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20)),
                      error: (e, _) => Center(
                        child: Text('Error: $e',
                            style: TextStyle(
                                color: AppThemeColors.of(context)
                                    .textSecondary)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Browse View ───────────────────────────────────────────────────────────────

class _BrowseView extends ConsumerWidget {
  final int? selectedGenre;

  const _BrowseView({this.selectedGenre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(genresProvider);
    final trending = ref.watch(trendingMoviesProvider);
    final popular = ref.watch(popularMoviesProvider);
    final genreState =
        selectedGenre != null ? ref.watch(genreMoviesProvider(selectedGenre!)) : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre chips — horizontal single row
          const SizedBox(height: 4),
          genres.when(
            data: (list) => _GenreChips(
              genres: list,
              selectedId: selectedGenre,
              onSelect: (id) =>
                  ref.read(selectedGenreProvider.notifier).state = id,
            ),
            loading: () => const _ShimmerChips(),
            error: (e, st) => _GenreChips(
              genres: kMovieGenres,
              selectedId: selectedGenre,
              onSelect: (id) =>
                  ref.read(selectedGenreProvider.notifier).state = id,
            ),
          ),

          if (selectedGenre == null) ...[
            // ── Trending Globally ───────────────────────────────────────
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Trending Globally',
              actionLabel: 'See all',
              onActionTap: () => context.push(
                  '/see-all?category=trending_movies&title=Trending+Globally&mediaType=movie'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 255,
              child: trending.when(
                data: (movies) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: movies.length,
                  itemBuilder: (ctx, i) {
                    final movie = movies[i];
                    return Padding(
                      padding: EdgeInsets.only(
                          right: i < movies.length - 1 ? 14 : 0),
                      child: _TrendingCard(
                        movie: movie,
                        onTap: () => ctx.push(movie.mediaType == 'tv'
                            ? '/tv/${movie.id}'
                            : '/movie/${movie.id}'),
                      ),
                    );
                  },
                ),
                loading: () => const _ShimmerTrendingRow(),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),

            // ── Top 10 ──────────────────────────────────────────────────
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Top 10',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 0.5),
                    ),
                    child: const Text(
                      'LOCAL PEAK',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            popular.when(
              data: (movies) => Column(
                children: movies.take(10).toList().asMap().entries.map((e) {
                  final movie = e.value;
                  return _Top10Tile(
                    movie: movie,
                    rank: e.key + 1,
                    onTap: () => context.push(movie.mediaType == 'tv'
                        ? '/tv/${movie.id}'
                        : '/movie/${movie.id}'),
                  );
                }).toList(),
              ),
              loading: () => const _ShimmerTop10(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 40),
          ] else ...[
            // ── Genre movies grid ────────────────────────────────────────
            const SizedBox(height: 24),
            if (genreState != null)
              genreState.when(
                data: (state) => Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: state.movies.length,
                      itemBuilder: (ctx, i) {
                        final movie = state.movies[i];
                        return MovieCard(
                          movie: movie,
                          width: double.infinity,
                          onTap: () => ctx.push(movie.mediaType == 'tv'
                              ? '/tv/${movie.id}'
                              : '/movie/${movie.id}'),
                        );
                      },
                    ),
                    if (state.hasMore) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: state.isLoadingMore
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => ref
                                      .read(genreMoviesProvider(
                                              selectedGenre!)
                                          .notifier)
                                      .loadMore(),
                                  child: const Text('Load More'),
                                ),
                              ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
                loading: () => const _ShimmerGrid(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Genre chips (horizontal single row) ──────────────────────────────────────

class _GenreChips extends StatelessWidget {
  final List<Genre> genres;
  final int? selectedId;
  final void Function(int?) onSelect;

  const _GenreChips({
    required this.genres,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: genres.length,
        itemBuilder: (context, i) {
          final g = genres[i];
          final selected = selectedId == g.id;
          return Padding(
            padding:
                EdgeInsets.only(right: i < genres.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(selected ? null : g.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : colors.border,
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Text(
                  g.name,
                  style: TextStyle(
                    color: selected
                        ? Colors.black
                        : colors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Trending card (poster + rating badge + title/genre below) ─────────────────

class _TrendingCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _TrendingCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final genreName = movie.genreIds.isNotEmpty
        ? (kGenreNames[movie.genreIds.first] ?? '')
        : '';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster with rating badge
            SizedBox(
              width: 130,
              height: 190,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: movie.hasPoster
                        ? CachedNetworkImage(
                            imageUrl:
                                AppConstants.posterUrl(movie.posterPath!),
                            width: 130,
                            height: 190,
                            fit: BoxFit.cover,
                            placeholder: (ctx, _) =>
                                _shimmerBox(ctx, colors),
                            errorWidget: (ctx, e, st) =>
                                _fallback(colors),
                          )
                        : _fallback(colors),
                  ),
                  // Rating badge — top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: colors.border.withValues(alpha: 0.5),
                            width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.primary, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            movie.ratingFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              [
                if (genreName.isNotEmpty) genreName,
                if (movie.year.isNotEmpty) movie.year,
              ].join(' • '),
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(BuildContext context, AppThemeColors colors) {
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: colors.card,
      child: Container(
        width: 130,
        height: 190,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _fallback(AppThemeColors colors) {
    return Container(
      width: 130,
      height: 190,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.movie_outlined, color: colors.textMuted, size: 40),
    );
  }
}

// ── Top 10 tile ───────────────────────────────────────────────────────────────

class _Top10Tile extends StatelessWidget {
  final Movie movie;
  final int rank;
  final VoidCallback onTap;

  const _Top10Tile(
      {required this.movie, required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final genreName = movie.genreIds.isNotEmpty
        ? (kGenreNames[movie.genreIds.first] ?? '')
        : '';

    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: rank == 1
            ? null
            : Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 34,
            child: Text(
              '$rank',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: rank == 1
                    ? 34
                    : rank <= 3
                        ? 30
                        : 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: movie.hasPoster
                ? CachedNetworkImage(
                    imageUrl: AppConstants.posterUrl(movie.posterPath!),
                    width: 44,
                    height: 62,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 44,
                    height: 62,
                    color: colors.surfaceVariant,
                    child: Icon(Icons.movie_outlined,
                        color: colors.textMuted, size: 18),
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.primary, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      movie.ratingFormatted,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (genreName.isNotEmpty) ...[
                      Text(' • ',
                          style:
                              TextStyle(color: colors.textMuted, fontSize: 12)),
                      Text(
                        genreName,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Trend icon
          Icon(
            rank <= 5 ? Icons.trending_up_rounded : Icons.remove_rounded,
            color: rank <= 5 ? const Color(0xFF4CAF50) : colors.textMuted,
            size: 20,
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: rank == 1
            ? _AnimatedGoldenBorder(borderRadius: 16, child: inner)
            : inner,
      ),
    );
  }
}

// ── Animated Golden Border ────────────────────────────────────────────────────

class _AnimatedGoldenBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;

  const _AnimatedGoldenBorder({
    required this.child,
    required this.borderRadius,
  });

  @override
  State<_AnimatedGoldenBorder> createState() => _AnimatedGoldenBorderState();
}

class _AnimatedGoldenBorderState extends State<_AnimatedGoldenBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => CustomPaint(
        foregroundPainter: _GoldenBorderPainter(
          progress: _controller.value,
          borderRadius: widget.borderRadius,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _GoldenBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;

  const _GoldenBorderPainter({
    required this.progress,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: const [
          Colors.transparent,
          Color(0xFFFFD700),
          Color(0xFFFFF4A0),
          Color(0xFFFFD700),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(2 * math.pi * progress),
      ).createShader(rect);
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(_GoldenBorderPainter old) => old.progress != progress;
}

// ── Search Results ────────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List movies;

  const _SearchResults({required this.movies});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (ctx, i) {
        final movie = movies[i];
        return MovieCard(
          movie: movie,
          width: double.infinity,
          onTap: () => ctx.push(movie.mediaType == 'tv'
              ? '/tv/${movie.id}'
              : '/movie/${movie.id}'),
        );
      },
    );
  }
}

// ── Empty Results ─────────────────────────────────────────────────────────────

class _EmptyResults extends StatelessWidget {
  final String query;

  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              color: AppThemeColors.of(context).textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different title or keyword',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ── Shimmer helpers ───────────────────────────────────────────────────────────

class _ShimmerGrid extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;

  const _ShimmerGrid({
    required this.padding,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Shimmer.fromColors(
      baseColor: c.surfaceVariant,
      highlightColor: c.card,
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: padding,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: 9,
        itemBuilder: (ctx, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(color: c.surfaceVariant),
        ),
      ),
    );
  }
}

class _ShimmerChips extends StatelessWidget {
  const _ShimmerChips();

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final widths = [72.0, 56.0, 88.0, 64.0, 80.0, 60.0, 76.0];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: widths.length,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(right: i < widths.length - 1 ? 8 : 0),
          child: Shimmer.fromColors(
            baseColor: c.surfaceVariant,
            highlightColor: c.card,
            child: Container(
              width: widths[i],
              height: 38,
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerTrendingRow extends StatelessWidget {
  const _ShimmerTrendingRow();

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(right: i < 5 ? 14 : 0),
        child: Shimmer.fromColors(
          baseColor: c.surfaceVariant,
          highlightColor: c.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 130,
                height: 190,
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                  width: 110, height: 13, color: c.surfaceVariant),
              const SizedBox(height: 5),
              Container(
                  width: 70, height: 11, color: c.surfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerTop10 extends StatelessWidget {
  const _ShimmerTop10();

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Column(
      children: List.generate(
        5,
        (i) => Shimmer.fromColors(
          baseColor: c.surfaceVariant,
          highlightColor: c.card,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            height: 86,
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
