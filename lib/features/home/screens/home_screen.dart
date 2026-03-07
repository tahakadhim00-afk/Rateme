import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/models/movie.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/featured_banner.dart';
import '../widgets/movie_row.dart';

// (category key, page, display title, cardWidth, cardHeight)
typedef _SectionConfig = (String, int, String, double, double);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  int _visibleExtra = 0;
  bool _loadingMore = false;

  // Sequence of extra sections loaded on scroll (pages 2, 3, 4, 5…)
  static const List<_SectionConfig> _queue = [
    ('popular_movies', 2, 'Popular Movies', 120.0, 178.0),
    ('top_rated_movies', 2, 'Top Rated', 130.0, 195.0),
    ('popular_tv', 2, 'Popular TV Shows', 120.0, 178.0),
    ('top_rated_tv', 2, 'Top Rated TV', 130.0, 195.0),
    ('now_playing', 2, 'Now Playing', 130.0, 195.0),
    ('airing_today', 2, 'Airing Today', 130.0, 195.0),
    ('upcoming', 2, 'Upcoming', 140.0, 210.0),
    ('popular_movies', 3, 'Popular Movies', 120.0, 178.0),
    ('top_rated_movies', 3, 'Top Rated', 130.0, 195.0),
    ('popular_tv', 3, 'Popular TV Shows', 120.0, 178.0),
    ('top_rated_tv', 3, 'Top Rated TV', 130.0, 195.0),
    ('now_playing', 3, 'Now Playing', 130.0, 195.0),
    ('airing_today', 3, 'Airing Today', 130.0, 195.0),
    ('popular_movies', 4, 'Popular Movies', 120.0, 178.0),
    ('top_rated_movies', 4, 'Top Rated', 130.0, 195.0),
    ('popular_tv', 4, 'Popular TV Shows', 120.0, 178.0),
    ('top_rated_tv', 4, 'Top Rated TV', 130.0, 195.0),
    ('popular_movies', 5, 'Popular Movies', 120.0, 178.0),
    ('top_rated_movies', 5, 'Top Rated', 130.0, 195.0),
    ('popular_tv', 5, 'Popular TV Shows', 120.0, 178.0),
    ('top_rated_tv', 5, 'Top Rated TV', 130.0, 195.0),
    ('airing_today', 4, 'Airing Today', 130.0, 195.0),
    ('upcoming', 3, 'Upcoming', 140.0, 210.0),
    ('popular_movies', 6, 'Popular Movies', 120.0, 178.0),
    ('top_rated_movies', 6, 'Top Rated', 130.0, 195.0),
    ('popular_tv', 6, 'Popular TV Shows', 120.0, 178.0),
    ('top_rated_tv', 6, 'Top Rated TV', 130.0, 195.0),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _visibleExtra >= _queue.length) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 500) {
      setState(() {
        _loadingMore = true;
        _visibleExtra = (_visibleExtra + 3).clamp(0, _queue.length);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _loadingMore = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Static providers (page 1)
    final trending = ref.watch(trendingMoviesProvider);
    final nowPlaying = ref.watch(nowPlayingProvider);
    final popular = ref.watch(popularMoviesProvider);
    final topRated = ref.watch(topRatedProvider);
    final upcoming = ref.watch(upcomingProvider);
    final trendingTv = ref.watch(trendingTvProvider);
    final airingToday = ref.watch(airingTodayProvider);
    final popularTv = ref.watch(popularTvProvider);
    final topRatedTv = ref.watch(topRatedTvProvider);

    // Dynamic extra sections — watch exactly as many as visible
    final extraData = <AsyncValue<List<Movie>>>[];
    for (int i = 0; i < _visibleExtra; i++) {
      final (cat, page, _, _, _) = _queue[i];
      extraData.add(ref.watch(paginatedSectionProvider((cat, page))));
    }

    final notifCount = ref.watch(notificationCountProvider);

    final slivers = <Widget>[
      _buildAppBar(context, notifCount),

      // Featured banner
      SliverToBoxAdapter(
        child: trending.when(
          data: (movies) => movies.isEmpty
              ? const SizedBox.shrink()
              : FeaturedBanner(movies: movies),
          loading: () => _BannerShimmer(),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      // ── Static rows ───────────────────────────────────────────────────────

      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: nowPlaying.when(
          data: (movies) => MovieRow(
            title: 'Now Playing',
            movies: movies,
            actionLabel: 'See All',
            onMovieTap: (m) => context.push('/movie/${m.id}'),
          ),
          loading: () => const MovieRow(title: 'Now Playing', isLoading: true),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: popular.when(
          data: (movies) => MovieRow(
            title: 'Popular Movies',
            movies: movies,
            actionLabel: 'See All',
            onMovieTap: (m) => context.push('/movie/${m.id}'),
            cardWidth: 120,
            cardHeight: 178,
          ),
          loading: () => const MovieRow(
              title: 'Popular Movies',
              isLoading: true,
              cardWidth: 120,
              cardHeight: 178),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: topRated.when(
          data: (movies) => MovieRow(
            title: 'Top Rated',
            movies: movies,
            actionLabel: 'See All',
            onMovieTap: (m) => context.push('/movie/${m.id}'),
          ),
          loading: () => const MovieRow(title: 'Top Rated', isLoading: true),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: upcoming.when(
          data: (movies) => MovieRow(
            title: 'Upcoming',
            movies: movies,
            actionLabel: 'See All',
            onMovieTap: (m) => context.push('/movie/${m.id}'),
            cardWidth: 140,
            cardHeight: 210,
          ),
          loading: () => const MovieRow(
              title: 'Upcoming',
              isLoading: true,
              cardWidth: 140,
              cardHeight: 210),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: trendingTv.when(
          data: (movies) => MovieRow(
            title: 'Trending TV Shows',
            movies: movies,
            actionLabel: 'See All',
            onMovieTap: (m) => context.push('/tv/${m.id}'),
          ),
          loading: () =>
              const MovieRow(title: 'Trending TV Shows', isLoading: true),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: airingToday.when(
          data: (movies) => MovieRow(
            title: 'Airing Today',
            movies: movies,
            actionLabel: 'See All',
            onMovieTap: (m) => context.push('/tv/${m.id}'),
            cardWidth: 140,
            cardHeight: 210,
          ),
          loading: () => const MovieRow(
              title: 'Airing Today',
              isLoading: true,
              cardWidth: 140,
              cardHeight: 210),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: popularTv.when(
          data: (movies) => MovieRow(
            title: 'Popular TV Shows',
            movies: movies,
            actionLabel: 'See All',
            onMovieTap: (m) => context.push('/tv/${m.id}'),
            cardWidth: 120,
            cardHeight: 178,
          ),
          loading: () => const MovieRow(
              title: 'Popular TV Shows',
              isLoading: true,
              cardWidth: 120,
              cardHeight: 178),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: topRatedTv.when(
          data: (movies) => MovieRow(
            title: 'Top Rated TV Shows',
            movies: movies,
            actionLabel: 'See All',
            onMovieTap: (m) => context.push('/tv/${m.id}'),
          ),
          loading: () =>
              const MovieRow(title: 'Top Rated TV Shows', isLoading: true),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      // ── Infinite-scroll extra sections ────────────────────────────────────

      for (int i = 0; i < _visibleExtra; i++) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
        SliverToBoxAdapter(
          child: extraData[i].when(
            data: (movies) {
              final cfg = _queue[i];
              return MovieRow(
                title: cfg.$3,
                movies: movies,
                onMovieTap: (m) => context.push(
                    m.mediaType == 'tv' ? '/tv/${m.id}' : '/movie/${m.id}'),
                cardWidth: cfg.$4,
                cardHeight: cfg.$5,
              );
            },
            loading: () {
              final cfg = _queue[i];
              return MovieRow(
                  title: cfg.$3,
                  isLoading: true,
                  cardWidth: cfg.$4,
                  cardHeight: cfg.$5);
            },
            error: (e, _) => const SizedBox.shrink(),
          ),
        ),
      ],

      // Loading indicator while fetching the next batch
      if (_loadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
        ),

      const SliverToBoxAdapter(child: SizedBox(height: 40)),
    ];

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: slivers,
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, int notifCount) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.movie_rounded, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'RateMe',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Badge(
          isLabelVisible: notifCount > 0,
          label: Text('$notifCount'),
          backgroundColor: AppColors.secondary,
          textColor: Colors.white,
          child: IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              ref.read(notificationCountProvider.notifier).state = 0;
              _showNotificationsSheet(context);
            },
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NotificationsSheet(),
    );
  }
}

// ── Notifications sheet ───────────────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  static const _items = [
    (
      Icons.star_rounded,
      'New Release',
      'Dune: Part Two is now available to rate.',
      '2h ago'
    ),
    (
      Icons.local_fire_department_rounded,
      'Trending Near You',
      'Oppenheimer is trending in your region.',
      '5h ago'
    ),
    (
      Icons.movie_filter_rounded,
      'Recommendation',
      'Based on your ratings, try Interstellar.',
      '1d ago'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: colors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Divider(color: colors.border, height: 1),
        for (final n in _items)
          _NotifTile(icon: n.$1, title: n.$2, body: n.$3, time: n.$4),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String time;

  const _NotifTile(
      {required this.icon,
      required this.title,
      required this.body,
      required this.time});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body,
              style: TextStyle(
                  color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(time,
              style: TextStyle(
                  color: colors.textMuted, fontSize: 11)),
        ],
      ),
      isThreeLine: true,
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _BannerShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: colors.card,
      child: Container(
        height: 440,
        color: colors.surfaceVariant,
      ),
    );
  }
}
