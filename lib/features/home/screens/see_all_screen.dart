import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/movie_card.dart';

class SeeAllScreen extends ConsumerStatefulWidget {
  final String category;
  final String title;
  final String mediaType; // 'movie' or 'tv'

  const SeeAllScreen({
    super.key,
    required this.category,
    required this.title,
    required this.mediaType,
  });

  @override
  ConsumerState<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends ConsumerState<SeeAllScreen> {
  final _scrollController = ScrollController();
  final List<Movie> _movies = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (!_loading && _hasMore && pos.pixels >= pos.maxScrollExtent - 400) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final results = await ref
          .read(tmdbServiceProvider)
          .getPage(widget.category, _page);
      if (!mounted) return;
      setState(() {
        if (results.isEmpty) {
          _hasMore = false;
        } else {
          _movies.addAll(results);
          _page++;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _hasMore = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTap(Movie movie) {
    final isTV = movie.mediaType == 'tv' || widget.mediaType == 'tv';
    context.push(isTV ? '/tv/${movie.id}' : '/movie/${movie.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _movies.isEmpty && _loading
          ? _SkeletonGrid(colors: colors)
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.67,
              ),
              itemCount: _movies.length + (_loading ? 6 : 0),
              itemBuilder: (ctx, i) {
                if (i >= _movies.length) {
                  return _ShimmerCard(colors: colors);
                }
                final movie = _movies[i];
                final width = (MediaQuery.of(context).size.width - 32 - 20) / 3;
                return MovieCard(
                  movie: movie,
                  width: width,
                  height: width / 0.67,
                  onTap: () => _onTap(movie),
                );
              },
            ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  final AppThemeColors colors;
  const _SkeletonGrid({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: colors.card,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 10,
          childAspectRatio: 0.67,
        ),
        itemCount: 18,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final AppThemeColors colors;
  const _ShimmerCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: colors.card,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
