import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/movie.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/featured_banner.dart';
import '../widgets/movie_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(trendingMoviesProvider);
    ref.invalidate(popularMoviesProvider);
    ref.invalidate(topRatedProvider);
    ref.invalidate(upcomingProvider);
    ref.invalidate(trendingTvProvider);
    ref.invalidate(airingTodayProvider);
    ref.invalidate(popularTvProvider);
    ref.invalidate(topRatedTvProvider);
    await ref.read(trendingMoviesProvider.future).catchError((_) => <Movie>[]);
  }

  String _greeting(String? fullName) {
    final hour = DateTime.now().hour;
    final time = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    if (fullName == null || fullName.trim().isEmpty) return 'RateMe';
    final firstName = fullName.trim().split(' ').first;
    return '$time, $firstName';
  }

  @override
  Widget build(BuildContext context) {
    final trending = ref.watch(trendingMoviesProvider);
    final popular = ref.watch(popularMoviesProvider);
    final topRated = ref.watch(topRatedProvider);
    final upcoming = ref.watch(upcomingProvider);
    final trendingTv = ref.watch(trendingTvProvider);
    final airingToday = ref.watch(airingTodayProvider);
    final popularTv = ref.watch(popularTvProvider);
    final topRatedTv = ref.watch(topRatedTvProvider);

    final notifCount = ref.watch(unreadNotifCountProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isSignedIn = ref.watch(isSignedInProvider);
    final watched = ref.watch(watchedProvider);

    final recentlyRated = isSignedIn
        ? (watched.where((i) => i.userRating != null).toList()
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt)))
        : <UserListItem>[];

    final userName = currentUser?.userMetadata?['full_name'] as String?;

    final slivers = <Widget>[
      _buildAppBar(context, notifCount, userName),

      // Featured banner
      SliverToBoxAdapter(
        child: trending.when(
          data: (movies) => movies.isEmpty
              ? const SizedBox.shrink()
              : FeaturedBanner(movies: movies),
          loading: () => _BannerShimmer(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ),

      // Popular Movies
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: popular.when(
          data: (movies) => movies.isEmpty
              ? const SizedBox.shrink()
              : MovieRow(
                  title: 'Popular Movies',
                  movies: movies,
                  actionLabel: 'See All',
                  onActionTap: () => context.push(
                      '/see-all?category=popular_movies&title=Popular+Movies&mediaType=movie'),
                  onMovieTap: (m) => context.push('/movie/${m.id}'),
                  cardWidth: 100,
                  cardHeight: 150,
                ),
          loading: () => const MovieRow(
              title: 'Popular Movies',
              isLoading: true,
              cardWidth: 100,
              cardHeight: 150),
          error: (_, _) => _SectionError(
              onRetry: () => ref.invalidate(popularMoviesProvider)),
        ),
      ),

      // Top Rated
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: topRated.when(
          data: (movies) => movies.isEmpty
              ? const SizedBox.shrink()
              : MovieRow(
                  title: 'Top Rated',
                  movies: movies,
                  actionLabel: 'See All',
                  onActionTap: () => context.push(
                      '/see-all?category=top_rated_movies&title=Top+Rated&mediaType=movie'),
                  onMovieTap: (m) => context.push('/movie/${m.id}'),
                ),
          loading: () => const MovieRow(title: 'Top Rated', isLoading: true),
          error: (_, _) =>
              _SectionError(onRetry: () => ref.invalidate(topRatedProvider)),
        ),
      ),

      // Upcoming Movies
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: upcoming.when(
          data: (movies) => movies.isEmpty
              ? const SizedBox.shrink()
              : MovieRow(
                  title: 'Upcoming Movies',
                  movies: movies,
                  actionLabel: 'See All',
                  onActionTap: () => context.push(
                      '/see-all?category=upcoming&title=Upcoming+Movies&mediaType=movie'),
                  onMovieTap: (m) => context.push('/movie/${m.id}'),
                  cardWidth: 100,
                  cardHeight: 150,
                ),
          loading: () => const MovieRow(
              title: 'Upcoming Movies',
              isLoading: true,
              cardWidth: 100,
              cardHeight: 150),
          error: (_, _) =>
              _SectionError(onRetry: () => ref.invalidate(upcomingProvider)),
        ),
      ),

      // Trending TV Shows
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: trendingTv.when(
          data: (movies) => movies.isEmpty
              ? const SizedBox.shrink()
              : MovieRow(
                  title: 'Trending TV Shows',
                  movies: movies,
                  actionLabel: 'See All',
                  onActionTap: () => context.push(
                      '/see-all?category=trending_tv&title=Trending+TV+Shows&mediaType=tv'),
                  onMovieTap: (m) => context.push('/tv/${m.id}'),
                ),
          loading: () =>
              const MovieRow(title: 'Trending TV Shows', isLoading: true),
          error: (_, _) =>
              _SectionError(onRetry: () => ref.invalidate(trendingTvProvider)),
        ),
      ),

      // Airing Today
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: airingToday.when(
          data: (movies) => movies.isEmpty
              ? const SizedBox.shrink()
              : MovieRow(
                  title: 'Airing Today',
                  movies: movies,
                  actionLabel: 'See All',
                  onActionTap: () => context.push(
                      '/see-all?category=airing_today&title=Airing+Today&mediaType=tv'),
                  onMovieTap: (m) => context.push('/tv/${m.id}'),
                  cardWidth: 120,
                  cardHeight: 180,
                ),
          loading: () => const MovieRow(
              title: 'Airing Today',
              isLoading: true,
              cardWidth: 120,
              cardHeight: 180),
          error: (_, _) =>
              _SectionError(onRetry: () => ref.invalidate(airingTodayProvider)),
        ),
      ),

      // Popular TV Shows
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: popularTv.when(
          data: (movies) => movies.isEmpty
              ? const SizedBox.shrink()
              : MovieRow(
                  title: 'Popular TV Shows',
                  movies: movies,
                  actionLabel: 'See All',
                  onActionTap: () => context.push(
                      '/see-all?category=popular_tv&title=Popular+TV+Shows&mediaType=tv'),
                  onMovieTap: (m) => context.push('/tv/${m.id}'),
                  cardWidth: 100,
                  cardHeight: 150,
                ),
          loading: () => const MovieRow(
              title: 'Popular TV Shows',
              isLoading: true,
              cardWidth: 100,
              cardHeight: 150),
          error: (_, _) =>
              _SectionError(onRetry: () => ref.invalidate(popularTvProvider)),
        ),
      ),

      // Top Rated TV Shows
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: topRatedTv.when(
          data: (movies) => movies.isEmpty
              ? const SizedBox.shrink()
              : MovieRow(
                  title: 'Top Rated TV Shows',
                  movies: movies,
                  actionLabel: 'See All',
                  onActionTap: () => context.push(
                      '/see-all?category=top_rated_tv&title=Top+Rated+TV+Shows&mediaType=tv'),
                  onMovieTap: (m) => context.push('/tv/${m.id}'),
                ),
          loading: () =>
              const MovieRow(title: 'Top Rated TV Shows', isLoading: true),
          error: (_, _) =>
              _SectionError(onRetry: () => ref.invalidate(topRatedTvProvider)),
        ),
      ),

      // Recently Rated (signed-in only)
      if (recentlyRated.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
        SliverToBoxAdapter(
          child: _RecentlyRatedRow(
            items: recentlyRated,
            onTap: (item) => item.mediaType == 'tv'
                ? context.push('/tv/${item.mediaId}')
                : context.push('/movie/${item.mediaId}'),
          ),
        ),
      ],

      const SliverToBoxAdapter(child: SizedBox(height: 40)),
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: slivers,
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, int notifCount, String? userName) {
    final greeting = _greeting(userName);
    final isPersonalized = userName != null && userName.trim().isNotEmpty;

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
            greeting,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: isPersonalized ? 17 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Badge(
            isLabelVisible: notifCount > 0,
            label: Text('$notifCount'),
            backgroundColor: AppColors.secondary,
            textColor: Colors.white,
            offset: const Offset(-2, 2),
            child: IconButton(
              icon: Icon(Icons.notifications_outlined,
                  color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => _showNotificationsSheet(context),
            ),
          ),
        ),
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

// ── Section Error ─────────────────────────────────────────────────────────────

class _SectionError extends StatelessWidget {
  final VoidCallback onRetry;

  const _SectionError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: colors.textMuted),
          const SizedBox(width: 8),
          Text(
            'Failed to load',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const Spacer(),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Recently Rated Row ────────────────────────────────────────────────────────

class _RecentlyRatedRow extends StatelessWidget {
  final List<UserListItem> items;
  final void Function(UserListItem) onTap;

  const _RecentlyRatedRow({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final display = items.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Your Ratings',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: display.length,
            itemBuilder: (_, i) {
              final item = display[i];
              return Padding(
                padding:
                    EdgeInsets.only(right: i < display.length - 1 ? 14 : 0),
                child: _RatedCard(
                  item: item,
                  onTap: () => onTap(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RatedCard extends StatelessWidget {
  final UserListItem item;
  final VoidCallback onTap;

  const _RatedCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        height: 165,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.posterPath != null
                  ? Image.network(
                      AppConstants.posterUrl(item.posterPath!),
                      width: 110,
                      height: 165,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _posterFallback(colors),
                    )
                  : _posterFallback(colors),
            ),
            // Rating badge
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 11, color: Colors.black),
                    const SizedBox(width: 2),
                    Text(
                      item.userRating!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.black,
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
    );
  }

  Widget _posterFallback(AppThemeColors colors) {
    return Container(
      width: 110,
      height: 165,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.movie_rounded, size: 32, color: colors.textMuted),
    );
  }
}

// ── Notifications Sheet ───────────────────────────────────────────────────────

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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.75),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount new',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () => ref
                            .read(readNotifProvider.notifier)
                            .markAllRead(allIds),
                        child: const Text(
                          'Read All',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 13),
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_off_outlined,
                                    size: 40, color: colors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'Nothing new right now',
                                  style:
                                      TextStyle(color: colors.textMuted),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              if (movies.isNotEmpty) ...[
                                _SectionLabel(
                                  icon: Icons.movie_rounded,
                                  label: 'Now in Cinemas',
                                  count: movies
                                      .where((m) =>
                                          !readIds.contains(m.id))
                                      .length,
                                ),
                                ...movies.map((m) => _NotifTile(
                                      movie: m,
                                      isRead: readIds.contains(m.id),
                                      onTap: () {
                                        ref
                                            .read(readNotifProvider
                                                .notifier)
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
                                  label: 'Airing Today',
                                  count: tvShows
                                      .where((m) =>
                                          !readIds.contains(m.id))
                                      .length,
                                ),
                                ...tvShows.map((m) => _NotifTile(
                                      movie: m,
                                      isRead: readIds.contains(m.id),
                                      onTap: () {
                                        ref
                                            .read(readNotifProvider
                                                .notifier)
                                            .markRead(m.id);
                                        final router =
                                            GoRouter.of(parentContext);
                                        Navigator.pop(context);
                                        router.push('/tv/${m.id}',
                                            extra: m);
                                      },
                                    )),
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

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _SectionLabel(
      {required this.icon, required this.label, this.count = 0});

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
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
        color: isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                      errorBuilder: (_, _, _) =>
                          _posterFallback(colors),
                    )
                  : _posterFallback(colors),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          movie.title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    movie.year.isNotEmpty ? movie.year : 'Coming soon',
                    style:
                        TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  if (movie.overview != null &&
                      movie.overview!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      movie.overview!,
                      style: TextStyle(
                          color: colors.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
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
