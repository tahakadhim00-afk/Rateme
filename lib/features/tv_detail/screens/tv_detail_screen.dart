import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/tv_detail.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/rating_badge.dart';
import '../../../shared/widgets/movie_card.dart';

class TvDetailScreen extends ConsumerWidget {
  final int tvId;
  const TvDetailScreen({super.key, required this.tvId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tvDetailProvider(tvId));
    return detailAsync.when(
      data: (tv) => _TvDetailView(tv: tv),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
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
    _syncGenreIds();
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, tv, isWatchLater, listNotifier),
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
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    TvDetail tv,
    bool isWatchLater,
    ListsNotifier listNotifier,
  ) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => listNotifier.toggleWatchLater(_tvAsMovie),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isWatchLater
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isWatchLater ? AppColors.primary : Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
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
                    AppThemeColors.of(context).background
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
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
                    if (tv.status != null)
                      _StatusBadge(isEnded: tv.isEnded, status: tv.status!),
                  ],
                ),
                const SizedBox(height: 10),
                RatingBadge(
                    rating: tv.voteAverage, fontSize: 14, iconSize: 16),
                const SizedBox(height: 4),
                Text(
                  '${_formatCount(tv.voteCount)} votes',
                  style: Theme.of(context).textTheme.labelSmall,
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
            onTap: () => listNotifier.toggleWatched(_tvAsMovie,
                runtime: tv.episodeRunTime.isNotEmpty
                    ? tv.numberOfEpisodes * tv.episodeRunTime.first
                    : null,
                genreIds: tv.genres.map((g) => g.id).toList()),
          ),
          const SizedBox(width: 12),
          _RoundActionBtn(
            icon: isWatchLater
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: 'Watch Later',
            active: isWatchLater,
            activeColor: AppColors.primary,
            onTap: () => listNotifier.toggleWatchLater(_tvAsMovie),
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
                        : null,
                    genreIds: tv.genres.map((g) => g.id).toList(),
                  );
                }
              },
            ),
            if (_userRating > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Your rating: ${(_userRating * 2).toStringAsFixed(1)} / 10',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? activeColor.withValues(alpha: 0.15)
                  : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? activeColor.withValues(alpha: 0.4)
                    : colors.border,
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
          );
        }),
      ),
    );
  }
}
