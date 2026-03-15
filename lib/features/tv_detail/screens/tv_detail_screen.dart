import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/tv_detail.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/rating_badge.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../movie_detail/widgets/share_rating_sheet.dart';

class TvDetailScreen extends ConsumerWidget {
  final int tvId;
  const TvDetailScreen({super.key, required this.tvId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tvDetailProvider(tvId));
    return detailAsync.when(
      data: (tv) => _TvDetailView(tv: tv),
      loading: () => const _TvDetailSkeleton(),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Builder(
          builder: (context) => Center(
            child: Text('Failed to load show',
                style: TextStyle(
                    color: AppThemeColors.of(context).textSecondary)),
          ),
        ),
      ),
    );
  }
}

class _TvDetailView extends ConsumerStatefulWidget {
  final TvDetail tv;
  const _TvDetailView({required this.tv});

  @override
  ConsumerState<_TvDetailView> createState() => _TvDetailViewState();
}

class _TvDetailViewState extends ConsumerState<_TvDetailView> {
  double _userRating = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initUserRating();
    _syncGenreIds();
  }

  void _initUserRating() {
    final watched = ref.read(listsProvider)[ListType.watched] ?? [];
    final item = watched.cast<UserListItem?>().firstWhere(
      (e) => e!.mediaId == widget.tv.id,
      orElse: () => null,
    );
    final saved = item?.userRating;
    if (saved != null && saved > 0) {
      setState(() => _userRating = saved / 2);
    }
  }

  void _syncGenreIds() {
    final tv = widget.tv;
    if (tv.genres.isEmpty) return;
    final watched = ref.read(listsProvider)[ListType.watched] ?? [];
    final item = watched.cast<UserListItem?>().firstWhere(
      (e) => e!.mediaId == tv.id,
      orElse: () => null,
    );
    if (item != null && item.genreIds.isEmpty) {
      ref.read(listsProvider.notifier).updateGenreIds(
        tv.id,
        tv.genres.map((g) => g.id).toList(),
      );
    }
  }

  Movie get _tvAsMovie => Movie(
        id: widget.tv.id,
        title: widget.tv.title,
        posterPath: widget.tv.posterPath,
        backdropPath: widget.tv.backdropPath,
        voteAverage: widget.tv.voteAverage,
        releaseDate: widget.tv.firstAirDate,
        mediaType: 'tv',
      );

  @override
  Widget build(BuildContext context) {
    final tv = widget.tv;
    final listNotifier = ref.read(listsProvider.notifier);
    final listsState = ref.watch(listsProvider);
    final isWatched =
        (listsState[ListType.watched] ?? []).any((e) => e.mediaId == tv.id);
    final isWatchLater =
        (listsState[ListType.watchLater] ?? []).any((e) => e.mediaId == tv.id);
    final recommendations = ref.watch(tvRecommendationsProvider(tv.id));

    final imageCover = Stack(
      fit: StackFit.expand,
      children: [
        if (tv.hasBackdrop)
          CachedNetworkImage(
            imageUrl: AppConstants.backdropUrl(tv.backdropPath!),
            fit: BoxFit.cover,
          )
        else if (tv.hasPoster)
          CachedNetworkImage(
            imageUrl: AppConstants.posterUrl(tv.posterPath!,
                size: AppConstants.posterW500),
            fit: BoxFit.cover,
          )
        else
          Container(color: AppThemeColors.of(context).surface),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppThemeColors.of(context).background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.4, 1.0],
            ),
          ),
        ),
      ],
    );

    final bgImageUrl = tv.hasBackdrop
        ? AppConstants.backdropUrl(tv.backdropPath!)
        : tv.hasPoster
            ? AppConstants.posterUrl(tv.posterPath!, size: AppConstants.posterW500)
            : null;

    return Scaffold(
      backgroundColor: AppThemeColors.of(context).background,
      body: Stack(
        children: [
          // Fixed blurred background — stays in place while content scrolls
          if (bgImageUrl != null) ...[
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: CachedNetworkImage(
                  imageUrl: bgImageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.78)),
            ),
          ],
          CustomScrollView(
            slivers: [
              // Header: trailer player or image (plain SliverToBoxAdapter — no transforms)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: imageCover,
                ),
              ),
              SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainInfo(context, tv),
                const SizedBox(height: 20),
                _buildActionButtons(
                    context, tv, isWatched, isWatchLater, listNotifier),
                const SizedBox(height: 24),
                _buildRatingSection(context, tv, listNotifier),
                const SizedBox(height: 24),
                if (tv.overview?.isNotEmpty == true) ...[
                  _buildSection(
                    context,
                    title: 'Overview',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(tv.overview!,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (tv.genres.isNotEmpty) ...[
                  _buildSection(
                    context,
                    title: 'Genres',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tv.genres
                            .map((g) => _GenreChip(name: g.name))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (tv.seasons.isNotEmpty) ...[
                  _buildSeasonsSection(context, tv),
                  const SizedBox(height: 24),
                ],
                if (tv.cast.isNotEmpty) ...[
                  _buildSection(
                    context,
                    title: 'Cast',
                    child: SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: tv.cast.length,
                        itemBuilder: (ctx, i) {
                          final actor = tv.cast[i];
                          return Padding(
                            padding: EdgeInsets.only(
                                right: i < tv.cast.length - 1 ? 14 : 0),
                            child: GestureDetector(
                              onTap: () =>
                                  ctx.push('/actor/${actor.id}'),
                              child: SizedBox(
                                width: 90,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: actor.profilePath != null
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  AppConstants.posterUrl(
                                                actor.profilePath!,
                                                size: '/w185',
                                              ),
                                              width: 90,
                                              height: 110,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 90,
                                              height: 110,
                                              color: AppThemeColors.of(
                                                      context)
                                                  .surfaceVariant,
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 40,
                                                color: AppThemeColors.of(
                                                        context)
                                                    .textMuted,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      actor.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              fontWeight:
                                                  FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (actor.character?.isNotEmpty ==
                                        true)
                                      Text(
                                        actor.character!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                                color: AppThemeColors.of(
                                                        context)
                                                    .textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
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
                  const SizedBox(height: 24),
                ],
                recommendations.when(
                  data: (shows) => shows.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text('More Like This',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 195,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                itemCount: shows.length,
                                itemBuilder: (ctx, i) => Padding(
                                  padding: EdgeInsets.only(
                                      right: i < shows.length - 1 ? 14 : 0),
                                  child: MovieCard(
                                    movie: shows[i],
                                    onTap: () =>
                                        ctx.push('/tv/${shows[i].id}'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
          ),
          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          // Floating status badge
          if (tv.status != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _StatusBadge(isEnded: tv.isEnded, status: tv.status!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainInfo(BuildContext context, TvDetail tv) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tv.hasPoster)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: AppConstants.posterUrl(tv.posterPath!),
                width: 110,
                height: 163,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tv.title,
                  style: Theme.of(context).textTheme.displaySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tv.tagline?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"${tv.tagline}"',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (tv.year.isNotEmpty)
                      _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: tv.year),
                    if (tv.numberOfSeasons > 0)
                      _InfoChip(
                          icon: Icons.layers_rounded,
                          label: '${tv.numberOfSeasons} season${tv.numberOfSeasons > 1 ? 's' : ''}'),
                    if (tv.episodeRuntimeFormatted.isNotEmpty)
                      _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: tv.episodeRuntimeFormatted),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    RatingBadge(
                        rating: tv.voteAverage, fontSize: 14, iconSize: 16, showBackground: false),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatCount(tv.voteCount)} votes',
                      style: Theme.of(context).textTheme.labelSmall,
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

  Widget _buildActionButtons(
    BuildContext context,
    TvDetail tv,
    bool isWatched,
    bool isWatchLater,
    ListsNotifier listNotifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _RoundActionBtn(
            icon: isWatched
                ? Icons.check_circle_rounded
                : Icons.check_circle_outline_rounded,
            label: 'Watched',
            active: isWatched,
            activeColor: AppColors.success,
            onTap: () {
              if (!ref.read(isSignedInProvider)) {
                _requireSignIn(context);
                return;
              }
              listNotifier.toggleWatched(_tvAsMovie,
                  runtime: tv.episodeRunTime.isNotEmpty
                      ? tv.numberOfEpisodes * tv.episodeRunTime.first
                      : tv.lastEpisodeRuntime != null
                          ? tv.numberOfEpisodes * tv.lastEpisodeRuntime!
                          : null,
                  genreIds: tv.genres.map((g) => g.id).toList());
            },
          ),
          const SizedBox(width: 12),
          _RoundActionBtn(
            icon: isWatchLater
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: 'Watch Later',
            active: isWatchLater,
            activeColor: AppColors.primary,
            onTap: () {
              if (!ref.read(isSignedInProvider)) {
                _requireSignIn(context);
                return;
              }
              listNotifier.toggleWatchLater(_tvAsMovie);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
      BuildContext context, TvDetail tv, ListsNotifier notifier) {
    return _buildSection(
      context,
      title: 'Rate This Show',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingBar.builder(
              initialRating: _userRating,
              minRating: 0.5,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (ctx, _) =>
                  const Icon(Icons.star_rounded, color: AppColors.primary),
              onRatingUpdate: (r) {
                if (!ref.read(isSignedInProvider)) {
                  _requireSignIn(context);
                  return;
                }
                setState(() => _userRating = r);
                final isWatched =
                    (ref.read(listsProvider)[ListType.watched] ?? [])
                        .any((e) => e.mediaId == tv.id);
                if (isWatched) {
                  notifier.updateRating(tv.id, r * 2);
                } else {
                  notifier.addToList(
                    ListType.watched,
                    _tvAsMovie,
                    userRating: r * 2,
                    runtime: tv.episodeRunTime.isNotEmpty
                        ? tv.numberOfEpisodes * tv.episodeRunTime.first
                        : tv.lastEpisodeRuntime != null
                            ? tv.numberOfEpisodes * tv.lastEpisodeRuntime!
                            : null,
                    genreIds: tv.genres.map((g) => g.id).toList(),
                  );
                }
              },
            ),
            if (_userRating > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Your rating: ${_userRating == _userRating.roundToDouble() ? _userRating.toInt() : _userRating.toStringAsFixed(1)} / 5',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showShareSheet(context, tv),
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  label: const Text('Share Rating'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonsSection(BuildContext context, TvDetail tv) {
    return _buildSection(
      context,
      title: 'Seasons  •  ${tv.seasons.length}',
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: tv.seasons.length,
          itemBuilder: (ctx, i) {
            final season = tv.seasons[i];
            return Padding(
              padding:
                  EdgeInsets.only(right: i < tv.seasons.length - 1 ? 12 : 0),
              child: GestureDetector(
                onTap: () =>
                    ctx.push('/tv/${tv.id}/season/${season.seasonNumber}'),
                child: _SeasonCard(season: season),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, TvDetail tv) {
    if (!ref.read(isSignedInProvider)) {
      _requireSignIn(context);
      return;
    }
    final user = ref.read(currentUserProvider);
    final username = (user?.userMetadata?['full_name'] as String?) ??
        user?.email?.split('@').first;
    final posterUrl = tv.posterPath != null
        ? AppConstants.posterUrl(tv.posterPath!, size: AppConstants.posterW500)
        : tv.backdropPath != null
            ? AppConstants.backdropUrl(tv.backdropPath!)
            : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareRatingSheet(
        title: tv.title,
        year: tv.year,
        posterUrl: posterUrl,
        rating: _userRating,
        username: username,
      ),
    );
  }

  void _requireSignIn(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sign in to rate and share',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child:
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ── Season Card ───────────────────────────────────────────────────────────────

class _SeasonCard extends StatelessWidget {
  final TvSeason season;
  const _SeasonCard({required this.season});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: season.hasPoster
                ? CachedNetworkImage(
                    imageUrl: AppConstants.posterUrl(season.posterPath!),
                    width: 110,
                    height: 130,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 110,
                    height: 130,
                    color: colors.surfaceVariant,
                    child: Icon(Icons.tv_rounded,
                        color: colors.textMuted, size: 36),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    season.name,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${season.episodeCount} eps',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Genre Chip ────────────────────────────────────────────────────────────────

class _GenreChip extends StatelessWidget {
  final String name;
  const _GenreChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Text(
        name,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isEnded;
  final String status;
  const _StatusBadge({required this.isEnded, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = isEnded ? AppColors.error : AppColors.success;
    return Text(
      status,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _TvDetailSkeleton extends StatelessWidget {
  const _TvDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.of(context).background,
      body: Shimmer.fromColors(
        baseColor: AppThemeColors.of(context).surfaceVariant,
        highlightColor: AppThemeColors.of(context).border,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero backdrop
              Container(height: 300, color: Colors.white),

              // Main info row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SBox(w: 110, h: 163, r: 14),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SBox(h: 22),
                          const SizedBox(height: 8),
                          _SBox(h: 22, w: 160),
                          const SizedBox(height: 14),
                          Row(children: [
                            _SBox(w: 76, h: 28, r: 8),
                            const SizedBox(width: 8),
                            _SBox(w: 68, h: 28, r: 8),
                            const SizedBox(width: 8),
                            _SBox(w: 72, h: 28, r: 8),
                          ]),
                          const SizedBox(height: 10),
                          _SBox(w: 72, h: 22, r: 6),
                          const SizedBox(height: 6),
                          _SBox(w: 80, h: 13, r: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(child: _SBox(h: 56, r: 14)),
                  const SizedBox(width: 12),
                  Expanded(child: _SBox(h: 56, r: 14)),
                ]),
              ),
              const SizedBox(height: 28),

              // Overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SBox(w: 80, h: 16, r: 4),
                    const SizedBox(height: 12),
                    _SBox(h: 14),
                    const SizedBox(height: 6),
                    _SBox(h: 14),
                    const SizedBox(height: 6),
                    _SBox(h: 14, w: 200),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Genres
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SBox(w: 60, h: 16, r: 4),
                    const SizedBox(height: 12),
                    Row(children: [
                      _SBox(w: 80, h: 32, r: 20),
                      const SizedBox(width: 8),
                      _SBox(w: 70, h: 32, r: 20),
                      const SizedBox(width: 8),
                      _SBox(w: 90, h: 32, r: 20),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Seasons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SBox(w: 100, h: 16, r: 4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                    child: _SBox(w: 110, h: 200, r: 14),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Cast
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SBox(w: 60, h: 16, r: 4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(right: i < 5 ? 14 : 0),
                    child: Column(children: [
                      _SBox(w: 90, h: 110, r: 12),
                      const SizedBox(height: 6),
                      _SBox(w: 66, h: 10, r: 4),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SBox extends StatelessWidget {
  final double? w;
  final double? h;
  final double r;
  const _SBox({this.w, this.h, this.r = 6});

  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}

// ── Round Action Button ────────────────────────────────────────────────────────

class _RoundActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _RoundActionBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Builder(builder: (context) {
          final colors = AppThemeColors.of(context);
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active
                      ? activeColor.withValues(alpha: 0.15)
                      : colors.surfaceVariant.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active
                        ? activeColor.withValues(alpha: 0.4)
                        : colors.border.withValues(alpha: 0.5),
                    width: active ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        size: 22,
                        color: active ? activeColor : colors.textMuted),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: active ? activeColor : colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
