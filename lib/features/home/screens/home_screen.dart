import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/models/movie.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/featured_banner.dart';
import '../widgets/movie_row.dart';

/// In-memory flag — true once onboarding has been shown this session.
/// Resets on every cold start, which is exactly what the dev-mode flow needs.
final _onboardingShownProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());
  }

  Future<void> _checkOnboarding() async {
    if (!mounted) return;
    final isSignedIn = ref.read(isSignedInProvider);
    if (!isSignedIn) return;
    // Guard: only redirect once per session so returning from onboarding
    // doesn't trigger an infinite loop.
    final alreadyShown = ref.read(_onboardingShownProvider);
    if (alreadyShown) return;
    ref.read(_onboardingShownProvider.notifier).state = true;
    // TODO: remove this line before release — forces onboarding on every launch
    if (mounted) context.go('/onboarding');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(trendingMoviesProvider);
    ref.invalidate(userPreferencesProvider);
    ref.invalidate(popularMoviesProvider);
    ref.invalidate(topRatedProvider);

    ref.invalidate(trendingTvProvider);
    ref.invalidate(airingTodayProvider);
    ref.invalidate(popularTvProvider);
    ref.invalidate(topRatedTvProvider);
    await ref.read(trendingMoviesProvider.future).catchError((_) => <Movie>[]);
  }

  @override
  Widget build(BuildContext context) {
    // Static providers (page 1)
    final trending = ref.watch(trendingMoviesProvider);
    final popular = ref.watch(popularMoviesProvider);
    final topRated = ref.watch(topRatedProvider);

    final trendingTv = ref.watch(trendingTvProvider);
    final airingToday = ref.watch(airingTodayProvider);
    final popularTv = ref.watch(popularTvProvider);
    final topRatedTv = ref.watch(topRatedTvProvider);

    final notifCount = ref.watch(unreadNotifCountProvider);
    final shownPrefs = ref
            .watch(userPreferencesProvider)
            .valueOrNull
            ?.take(3)
            .toList() ??
        [];

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
        child: popular.when(
          data: (movies) => MovieRow(
            title: 'Popular Movies',
            movies: movies,
            actionLabel: 'See All',
            onActionTap: () => context.push('/see-all?category=popular_movies&title=Popular+Movies&mediaType=movie'),
            onMovieTap: (m) => context.push('/movie/${m.id}'),
            cardWidth: 100,
            cardHeight: 150,
          ),
          loading: () => const MovieRow(
              title: 'Popular Movies',
              isLoading: true,
              cardWidth: 100,
              cardHeight: 150),
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
            onActionTap: () => context.push('/see-all?category=top_rated_movies&title=Top+Rated&mediaType=movie'),
            onMovieTap: (m) => context.push('/movie/${m.id}'),
          ),
          loading: () => const MovieRow(title: 'Top Rated', isLoading: true),
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
            onActionTap: () => context.push('/see-all?category=trending_tv&title=Trending+TV+Shows&mediaType=tv'),
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
            onActionTap: () => context.push('/see-all?category=airing_today&title=Airing+Today&mediaType=tv'),
            onMovieTap: (m) => context.push('/tv/${m.id}'),
            cardWidth: 120,
            cardHeight: 180,
          ),
          loading: () => const MovieRow(
              title: 'Airing Today',
              isLoading: true,
              cardWidth: 120,
              cardHeight: 180),
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
            onActionTap: () => context.push('/see-all?category=popular_tv&title=Popular+TV+Shows&mediaType=tv'),
            onMovieTap: (m) => context.push('/tv/${m.id}'),
            cardWidth: 100,
            cardHeight: 150,
          ),
          loading: () => const MovieRow(
              title: 'Popular TV Shows',
              isLoading: true,
              cardWidth: 100,
              cardHeight: 150),
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
            onActionTap: () => context.push('/see-all?category=top_rated_tv&title=Top+Rated+TV+Shows&mediaType=tv'),
            onMovieTap: (m) => context.push('/tv/${m.id}'),
          ),
          loading: () =>
              const MovieRow(title: 'Top Rated TV Shows', isLoading: true),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),

      // ── Personalised rows ("Because you like…") ───────────────────────────
      ...shownPrefs.map(
        (pref) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: _PersonalisedRow(pref: pref),
          ),
        ),
      ),

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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.75),
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
        ),
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

// ── Personalised row ─────────────────────────────────────────────────────────

class _PersonalisedRow extends ConsumerWidget {
  final dynamic pref; // PersonPreference

  const _PersonalisedRow({required this.pref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(personMoviesProvider(pref));
    final label = pref.personType == 'director'
        ? 'Films by ${pref.personName}'
        : 'Because you like ${pref.personName}';

    return moviesAsync.when(
      loading: () => MovieRow(title: label, isLoading: true),
      error: (e, s) => const SizedBox.shrink(),
      data: (movies) {
        if (movies.isEmpty) return const SizedBox.shrink();
        return MovieRow(
          title: label,
          movies: movies,
          onMovieTap: (m) => context.push('/movie/${m.id}'),
        );
      },
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
