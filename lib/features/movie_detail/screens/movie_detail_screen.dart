import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/movie_detail.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/rating_badge.dart';
import '../../../shared/widgets/movie_card.dart';

class MovieDetailScreen extends ConsumerWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(movieDetailProvider(movieId));

    return detailAsync.when(
      data: (movie) => _DetailView(movie: movie),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Builder(
          builder: (context) => Center(
            child: Text('Failed to load movie',
                style: TextStyle(color: AppThemeColors.of(context).textSecondary)),
          ),
        ),
      ),
    );
  }
}

class _DetailView extends ConsumerStatefulWidget {
  final MovieDetail movie;

  const _DetailView({required this.movie});

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  double _userRating = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGenreIds();
  }

  void _syncGenreIds() {
    final movie = widget.movie;
    if (movie.genres.isEmpty) return;
    final watched = ref.read(listsProvider)[ListType.watched] ?? [];
    final item = watched.cast<UserListItem?>().firstWhere(
      (e) => e!.mediaId == movie.id,
      orElse: () => null,
    );
    if (item != null && item.genreIds.isEmpty) {
      ref.read(listsProvider.notifier).updateGenreIds(
        movie.id,
        movie.genres.map((g) => g.id).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final listNotifier = ref.read(listsProvider.notifier);
    final listsState   = ref.watch(listsProvider);
    final isWatched    = (listsState[ListType.watched]    ?? []).any((e) => e.mediaId == movie.id);
    final isWatchLater = (listsState[ListType.watchLater] ?? []).any((e) => e.mediaId == movie.id);

    final recommendations = ref.watch(movieRecommendationsProvider(movie.id));
    final castAsync = ref.watch(movieCastProvider(movie.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, movie, isWatchLater, listNotifier),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainInfo(context, movie),
                const SizedBox(height: 20),
                _buildActionButtons(
                    context, movie, isWatched, isWatchLater, listNotifier),
                const SizedBox(height: 24),
                if (movie.overview?.isNotEmpty == true) ...[
                  _buildSection(
                    context,
                    title: 'Overview',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        movie.overview!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // User rating
                _buildRatingSection(context, movie, listNotifier),
                const SizedBox(height: 24),

                // Genres
                if (movie.genres.isNotEmpty) ...[
                  _buildSection(
                    context,
                    title: 'Genres',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: movie.genres
                            .map((g) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppThemeColors.of(context).surfaceVariant,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppThemeColors.of(context).border, width: 0.5),
                                  ),
                                  child: Text(
                                    g.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                            color: AppThemeColors.of(context).textSecondary),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Cast
                castAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (castList) => castList.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              context,
                              title: 'Actors',
                              child: SizedBox(
                                height: 160,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  itemCount: castList.length,
                                  itemBuilder: (ctx, i) {
                                    final actor = castList[i];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          right: i < castList.length - 1
                                              ? 14
                                              : 0),
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
                                                        imageUrl: AppConstants
                                                            .posterUrl(
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
                                                        color: AppThemeColors
                                                                .of(context)
                                                            .surfaceVariant,
                                                        child: Icon(
                                                          Icons.person_rounded,
                                                          size: 40,
                                                          color: AppThemeColors
                                                                  .of(context)
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
                                                          color: AppThemeColors
                                                                  .of(context)
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
                        ),
                ),

                // Recommendations
                recommendations.when(
                  data: (movies) => movies.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'More Like This',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 195,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                itemCount: movies.length,
                                itemBuilder: (ctx, i) => Padding(
                                  padding: EdgeInsets.only(
                                      right: i < movies.length - 1 ? 14 : 0),
                                  child: MovieCard(
                                    movie: movies[i],
                                    onTap: () => ctx
                                        .push('/movie/${movies[i].id}'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, s) => const SizedBox.shrink(),
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
    MovieDetail movie,
    bool isWatchLater,
    ListsNotifier listNotifier,
  ) {
    // Convert MovieDetail to Movie for list operations
    final movieAsMovie = Movie(
      id: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      voteAverage: movie.voteAverage,
      releaseDate: movie.releaseDate,
    );

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
          onTap: () => listNotifier.toggleWatchLater(movieAsMovie),
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
            if (movie.hasBackdrop)
              CachedNetworkImage(
                imageUrl: AppConstants.backdropUrl(movie.backdropPath!),
                fit: BoxFit.cover,
              )
            else if (movie.hasPoster)
              CachedNetworkImage(
                imageUrl: AppConstants.posterUrl(movie.posterPath!,
                    size: AppConstants.posterW500),
                fit: BoxFit.cover,
              )
            else
              Container(color: AppThemeColors.of(context).surface),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppThemeColors.of(context).background],
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

  Widget _buildMainInfo(BuildContext context, MovieDetail movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          if (movie.hasPoster)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: AppConstants.posterUrl(movie.posterPath!),
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
                  movie.title,
                  style: Theme.of(context).textTheme.displaySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (movie.tagline?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"${movie.tagline}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                _InfoRow(
                  children: [
                    if (movie.year.isNotEmpty)
                      _InfoChip(icon: Icons.calendar_today_rounded, label: movie.year),
                    if (movie.runtimeFormatted.isNotEmpty)
                      _InfoChip(icon: Icons.schedule_rounded, label: movie.runtimeFormatted),
                  ],
                ),
                const SizedBox(height: 10),
                RatingBadge(rating: movie.voteAverage, fontSize: 14, iconSize: 16),
                const SizedBox(height: 4),
                Text(
                  '${_formatCount(movie.voteCount)} votes',
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
    MovieDetail movie,
    bool isWatched,
    bool isWatchLater,
    ListsNotifier listNotifier,
  ) {
    final movieAsMovie = Movie(
      id: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      voteAverage: movie.voteAverage,
      releaseDate: movie.releaseDate,
    );

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
            onTap: () => listNotifier.toggleWatched(movieAsMovie,
                runtime: movie.runtime,
                genreIds: movie.genres.map((g) => g.id).toList()),
          ),
          const SizedBox(width: 12),
          _RoundActionBtn(
            icon: isWatchLater
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: 'Watch Later',
            active: isWatchLater,
            activeColor: AppColors.primary,
            onTap: () => listNotifier.toggleWatchLater(movieAsMovie),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
      BuildContext context, MovieDetail movie, ListsNotifier notifier) {
    final movieAsMovie = Movie(
      id: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      voteAverage: movie.voteAverage,
      releaseDate: movie.releaseDate,
    );

    return _buildSection(
      context,
      title: 'Rate This Movie',
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
              itemBuilder: (ctx, _) => const Icon(
                Icons.star_rounded,
                color: AppColors.primary,
              ),
              onRatingUpdate: (r) {
                setState(() => _userRating = r);
                final isWatched = (ref.read(listsProvider)[ListType.watched] ?? [])
                    .any((e) => e.mediaId == movie.id);
                if (isWatched) {
                  notifier.updateRating(movie.id, r * 2);
                } else {
                  notifier.addToList(ListType.watched, movieAsMovie,
                      userRating: r * 2,
                      runtime: movie.runtime,
                      genreIds: movie.genres.map((g) => g.id).toList());
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

  Widget _buildSection(BuildContext context,
      {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
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

class _InfoRow extends StatelessWidget {
  final List<Widget> children;

  const _InfoRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: children,
    );
  }
}

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
                color: active ? activeColor.withValues(alpha: 0.4) : colors.border,
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
