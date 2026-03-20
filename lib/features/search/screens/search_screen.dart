import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/genre.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../shared/widgets/section_header.dart';

enum _SearchFilter { all, movies, tv }

enum _GenreMedia { movie, tv }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  _SearchFilter _filter = _SearchFilter.all;
  _GenreMedia _genreMedia = _GenreMedia.movie;
  List<String> _recentSearches = [];
  bool _showRecents = false;

  @override
  void initState() {
    super.initState();
    _loadRecents();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    final query = ref.read(searchQueryProvider);
    setState(() {
      _showRecents = _focusNode.hasFocus &&
          query.trim().isEmpty &&
          _recentSearches.isNotEmpty;
    });
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      ref.read(searchQueryProvider.notifier).state = '';
      setState(() {
        _showRecents =
            _focusNode.hasFocus && _recentSearches.isNotEmpty;
      });
      return;
    }
    setState(() => _showRecents = false);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).state = v;
      _saveRecent(v.trim());
    });
  }

  void _applyQuery(String q) {
    _controller.text = q;
    ref.read(searchQueryProvider.notifier).state = q;
    setState(() => _showRecents = false);
    _focusNode.unfocus();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('search_recent_v1') ?? [];
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _saveRecent(String q) async {
    final updated =
        [q, ..._recentSearches.where((s) => s != q)].take(8).toList();
    setState(() => _recentSearches = updated);
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('search_recent_v1', updated);
  }

  Future<void> _removeRecent(String q) async {
    final updated = _recentSearches.where((s) => s != q).toList();
    setState(() => _recentSearches = updated);
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('search_recent_v1', updated);
  }

  Future<void> _clearAllRecents() async {
    setState(() {
      _recentSearches = [];
      _showRecents = false;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('search_recent_v1');
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final selectedGenre = ref.watch(selectedGenreProvider);
    final colors = AppThemeColors.of(context);
    final isSearching = query.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(color: colors.textPrimary),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search movies, actors, directors',
                  prefixIcon:
                      Icon(Icons.search_rounded, color: colors.textMuted),
                  suffixIcon: _controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            _debounce?.cancel();
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() {
                              _showRecents = _focusNode.hasFocus &&
                                  _recentSearches.isNotEmpty;
                            });
                          },
                          child: Icon(Icons.close_rounded,
                              color: colors.textMuted),
                        )
                      : null,
                ),
              ),
            ),

            // Content
            Expanded(
              child: isSearching
                  ? _CombinedSearchResults(
                      query: query,
                      filter: _filter,
                      onFilterChange: (f) => setState(() => _filter = f),
                    )
                  : _showRecents
                      ? _RecentSearches(
                          recents: _recentSearches,
                          onTap: _applyQuery,
                          onRemove: _removeRecent,
                          onClearAll: _clearAllRecents,
                        )
                      : _BrowseView(
                          selectedGenre: selectedGenre,
                          genreMedia: _genreMedia,
                          onGenreMediaChange: (m) => setState(() {
                            _genreMedia = m;
                            ref
                                .read(selectedGenreProvider.notifier)
                                .state = null;
                          }),
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
  final _GenreMedia genreMedia;
  final ValueChanged<_GenreMedia> onGenreMediaChange;

  const _BrowseView({
    this.selectedGenre,
    required this.genreMedia,
    required this.onGenreMediaChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingMoviesProvider);
    final popular = ref.watch(popularMoviesProvider);
    final genres =
        genreMedia == _GenreMedia.movie ? kMovieGenres : kTvGenres;
    final genreState = selectedGenre != null
        ? (genreMedia == _GenreMedia.movie
            ? ref.watch(genreMoviesProvider(selectedGenre!))
            : ref.watch(genreTvMoviesProvider(selectedGenre!)))
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media type toggle
          const SizedBox(height: 8),
          _GenreMediaToggle(
            selected: genreMedia,
            onSelect: onGenreMediaChange,
          ),
          const SizedBox(height: 12),

          // Genre chips
          _GenreChips(
            genres: genres,
            selectedId: selectedGenre,
            onSelect: (id) =>
                ref.read(selectedGenreProvider.notifier).state = id,
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
                error: (_, _) => _BrowseError(
                    onRetry: () => ref.invalidate(trendingMoviesProvider)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.4),
                          width: 0.5),
                    ),
                    child: const Text(
                      'THIS WEEK',
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
              error: (_, _) => _BrowseError(
                  onRetry: () => ref.invalidate(popularMoviesProvider)),
            ),
            const SizedBox(height: 40),
          ] else ...[
            // ── Genre grid ───────────────────────────────────────────────
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
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => genreMedia ==
                                          _GenreMedia.movie
                                      ? ref
                                          .read(genreMoviesProvider(
                                                  selectedGenre!)
                                              .notifier)
                                          .loadMore()
                                      : ref
                                          .read(genreTvMoviesProvider(
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
                error: (_, _) => _BrowseError(
                  onRetry: () => genreMedia == _GenreMedia.movie
                      ? ref.invalidate(genreMoviesProvider(selectedGenre!))
                      : ref.invalidate(
                          genreTvMoviesProvider(selectedGenre!)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Genre Media Toggle ────────────────────────────────────────────────────────

class _GenreMediaToggle extends StatelessWidget {
  final _GenreMedia selected;
  final ValueChanged<_GenreMedia> onSelect;

  const _GenreMediaToggle(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleOption(
              label: 'Movies',
              selected: selected == _GenreMedia.movie,
              onTap: () => onSelect(_GenreMedia.movie),
            ),
            const SizedBox(width: 2),
            _ToggleOption(
              label: 'TV Shows',
              selected: selected == _GenreMedia.tv,
              onTap: () => onSelect(_GenreMedia.tv),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.black
                : AppThemeColors.of(context).textSecondary,
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Genre chips ───────────────────────────────────────────────────────────────

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
                    color:
                        selected ? AppColors.primary : colors.border,
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

// ── Browse section error ──────────────────────────────────────────────────────

class _BrowseError extends StatelessWidget {
  final VoidCallback onRetry;

  const _BrowseError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 32, color: colors.textMuted),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Trending card ─────────────────────────────────────────────────────────────

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
                            errorWidget: (ctx, _, _) =>
                                _fallback(colors),
                          )
                        : _fallback(colors),
                  ),
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
                            color:
                                colors.border.withValues(alpha: 0.5),
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
      child:
          Icon(Icons.movie_outlined, color: colors.textMuted, size: 40),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: rank == 1
            ? null
            : Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        children: [
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
                          style: TextStyle(
                              color: colors.textMuted, fontSize: 12)),
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
          Icon(
            rank <= 5
                ? Icons.trending_up_rounded
                : Icons.remove_rounded,
            color: rank <= 5
                ? const Color(0xFF4CAF50)
                : colors.textMuted,
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
  State<_AnimatedGoldenBorder> createState() =>
      _AnimatedGoldenBorderState();
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
    final rRect =
        RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
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
  bool shouldRepaint(_GoldenBorderPainter old) =>
      old.progress != progress;
}

// ── Combined Search Results ───────────────────────────────────────────────────

class _CombinedSearchResults extends ConsumerWidget {
  final String query;
  final _SearchFilter filter;
  final ValueChanged<_SearchFilter> onFilterChange;

  const _CombinedSearchResults({
    required this.query,
    required this.filter,
    required this.onFilterChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(searchResultsProvider);
    final peopleAsync = ref.watch(searchPeopleProvider);
    final watched = ref.watch(watchedProvider);
    final watchLater = ref.watch(watchLaterProvider);

    final watchedIds = watched.map((i) => i.mediaId).toSet();
    final watchLaterIds = watchLater.map((i) => i.mediaId).toSet();
    final ratedMap = {
      for (final i in watched)
        if (i.userRating != null) i.mediaId: i.userRating!,
    };

    return moviesAsync.when(
      loading: () => const _ShimmerGrid(
          padding: EdgeInsets.symmetric(horizontal: 20)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48,
                color: AppThemeColors.of(context).textMuted),
            const SizedBox(height: 12),
            Text('Search failed',
                style: TextStyle(
                    color: AppThemeColors.of(context).textMuted)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.invalidate(searchResultsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
      data: (allMovies) {
        final people = peopleAsync.valueOrNull ?? [];

        // Apply type filter
        final movies = filter == _SearchFilter.all
            ? allMovies
            : filter == _SearchFilter.movies
                ? allMovies
                    .where((m) => m.mediaType == 'movie')
                    .toList()
                : allMovies
                    .where((m) => m.mediaType == 'tv')
                    .toList();

        final showPeople =
            filter == _SearchFilter.all && people.isNotEmpty;
        final hasMovies = movies.isNotEmpty;

        if (allMovies.isEmpty && people.isEmpty) {
          return _EmptyResults(query: query);
        }

        return CustomScrollView(
          slivers: [
            // Filter chips
            SliverToBoxAdapter(
              child: _SearchFilterRow(
                filter: filter,
                onSelect: onFilterChange,
              ),
            ),

            // People section
            if (showPeople) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Text(
                    'People',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: people.length,
                    itemBuilder: (ctx, i) {
                      final person = people[i];
                      final id = person['id'] as int;
                      final name =
                          person['name'] as String? ?? '';
                      final profilePath =
                          person['profile_path'] as String?;
                      final dept =
                          person['known_for_department'] as String? ??
                              '';
                      return Padding(
                        padding: EdgeInsets.only(
                            right: i < people.length - 1 ? 16 : 0),
                        child: GestureDetector(
                          onTap: () => ctx.push('/actor/$id'),
                          child: SizedBox(
                            width: 72,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor:
                                      AppThemeColors.of(ctx)
                                          .surfaceVariant,
                                  backgroundImage:
                                      profilePath != null
                                          ? CachedNetworkImageProvider(
                                              AppConstants.posterUrl(
                                                  profilePath,
                                                  size: '/w185'),
                                            )
                                          : null,
                                  child: profilePath == null
                                      ? Icon(Icons.person_rounded,
                                          color: AppThemeColors.of(ctx)
                                              .textMuted,
                                          size: 30)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppThemeColors.of(ctx)
                                        .textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (dept.isNotEmpty)
                                  Text(
                                    dept,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppThemeColors.of(ctx)
                                          .textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Movies/TV section
            if (hasMovies) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, showPeople ? 20 : 16, 20, 14),
                  child: Row(
                    children: [
                      Text(
                        'Movies & TV',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${movies.length} result${movies.length == 1 ? '' : 's'}',
                        style: TextStyle(
                            color:
                                AppThemeColors.of(context).textMuted,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final movie = movies[i];
                      return Stack(
                        children: [
                          MovieCard(
                            movie: movie,
                            width: double.infinity,
                            onTap: () => ctx.push(
                                movie.mediaType == 'tv'
                                    ? '/tv/${movie.id}'
                                    : '/movie/${movie.id}'),
                          ),
                          _UserStatusBadge(
                            isWatched:
                                watchedIds.contains(movie.id),
                            isWatchLater:
                                watchLaterIds.contains(movie.id),
                            userRating: ratedMap[movie.id],
                          ),
                        ],
                      );
                    },
                    childCount: movies.length,
                  ),
                ),
              ),
            ] else ...[
              SliverToBoxAdapter(
                child: _EmptyResults(query: query),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Search Filter Row ─────────────────────────────────────────────────────────

class _SearchFilterRow extends StatelessWidget {
  final _SearchFilter filter;
  final ValueChanged<_SearchFilter> onSelect;

  const _SearchFilterRow(
      {required this.filter, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: filter == _SearchFilter.all,
            onTap: () => onSelect(_SearchFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Movies',
            selected: filter == _SearchFilter.movies,
            onTap: () => onSelect(_SearchFilter.movies),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'TV Shows',
            selected: filter == _SearchFilter.tv,
            onTap: () => onSelect(_SearchFilter.tv),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : colors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? Colors.black : colors.textSecondary,
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── User Status Badge ─────────────────────────────────────────────────────────

class _UserStatusBadge extends StatelessWidget {
  final bool isWatched;
  final bool isWatchLater;
  final double? userRating;

  const _UserStatusBadge({
    required this.isWatched,
    required this.isWatchLater,
    this.userRating,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWatched && !isWatchLater && userRating == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 6,
      left: 6,
      child: userRating != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 10, color: Colors.black),
                  const SizedBox(width: 2),
                  Text(
                    userRating!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isWatched
                    ? const Color(0xFF4CAF50)
                    : Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWatched
                    ? Icons.check_rounded
                    : Icons.bookmark_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
    );
  }
}

// ── Recent Searches ───────────────────────────────────────────────────────────

class _RecentSearches extends StatelessWidget {
  final List<String> recents;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  const _RecentSearches({
    required this.recents,
    required this.onTap,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
          child: Row(
            children: [
              Text(
                'Recent',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear all',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        ...recents.map(
          (q) => InkWell(
            onTap: () => onTap(q),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 11),
              child: Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 18, color: colors.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q,
                      style: TextStyle(
                          color: colors.textPrimary, fontSize: 15),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onRemove(q),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: colors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
        physics: shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : null,
        padding: padding,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
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
            margin:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
