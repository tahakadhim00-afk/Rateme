import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/notification_provider.dart';
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

    final notifCount = ref.watch(unreadNotifCountProvider);

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
          Image.asset(
            'assets/logo_and_images/app_bar.png',
            width: 34,
            height: 34,
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
            onPressed: () => _showNotificationsSheet(context),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(parentContext: context),
    );
  }
}

// ── Notifications sheet ───────────────────────────────────────────────────────

class _NotificationsSheet extends ConsumerWidget {
  final BuildContext parentContext;
  const _NotificationsSheet({required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppThemeColors.of(context);
    final readIds = ref.watch(readNotifProvider);
    final nowPlaying = ref.watch(nowPlayingProvider);
    final airingToday = ref.watch(airingTodayProvider);

    final movies = nowPlaying.asData?.value.take(5).toList() ?? [];
    final tvShows = airingToday.asData?.value.take(5).toList() ?? [];
    final allIds = [...movies, ...tvShows].map((m) => m.id);
    final unreadCount =
        allIds.where((id) => !readIds.contains(id)).length;
    final isLoading =
        nowPlaying is AsyncLoading || airingToday is AsyncLoading;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
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
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () => ref
                        .read(readNotifProvider.notifier)
                        .markAllRead(allIds),
                    child: const Text(
                      'Read All',
                      style:
                          TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),
          // Body
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : (movies.isEmpty && tvShows.isEmpty)
                    ? Center(
                        child: Text('Nothing new right now',
                            style: TextStyle(color: colors.textMuted)))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          if (movies.isNotEmpty) ...[
                            _SectionLabel(
                                icon: Icons.movie_rounded,
                                label: 'Now in Cinemas'),
                            ...movies.map((m) => _NotifTile(
                                  movie: m,
                                  isRead: readIds.contains(m.id),
                                  onTap: () {
                                    ref
                                        .read(readNotifProvider.notifier)
                                        .markRead(m.id);
                                    final router =
                                        GoRouter.of(parentContext);
                                    Navigator.pop(context);
                                    router.push('/movie/${m.id}',
                                        extra: m);
                                  },
                                )),
                          ],
                          if (tvShows.isNotEmpty) ...[
                            _SectionLabel(
                                icon: Icons.tv_rounded,
                                label: 'Airing Today'),
                            ...tvShows.map((m) => _NotifTile(
                                  movie: m,
                                  isRead: readIds.contains(m.id),
                                  onTap: () {
                                    ref
                                        .read(readNotifProvider.notifier)
                                        .markRead(m.id);
                                    final router =
                                        GoRouter.of(parentContext);
                                    Navigator.pop(context);
                                    router.push('/tv/${m.id}', extra: m);
                                  },
                                )),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.textMuted),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Movie movie;
  final bool isRead;
  final VoidCallback onTap;

  const _NotifTile({
    required this.movie,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Unread dot
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead
                    ? Colors.transparent
                    : AppColors.primary,
              ),
            ),
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: movie.posterPath != null
                  ? Image.network(
                      AppConstants.posterUrl(movie.posterPath!,
                          size: AppConstants.posterW342),
                      width: 38,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, stack) => _posterFallback(colors),
                    )
                  : _posterFallback(colors),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight:
                          isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    movie.year.isNotEmpty ? movie.year : 'Coming soon',
                    style: TextStyle(
                        color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _posterFallback(AppThemeColors colors) {
    return Container(
      width: 38,
      height: 56,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.movie_rounded, size: 18, color: colors.textMuted),
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
