// ignore: unnecessary_import
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/movie_detail.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/rating_badge.dart';
import '../../../shared/widgets/movie_card.dart';
import '../widgets/share_rating_sheet.dart';
import '../widgets/recommend_share_sheet.dart';
import '../../../shared/widgets/add_to_list_sheet.dart';

class MovieDetailScreen extends ConsumerWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(movieDetailProvider(movieId));

    return detailAsync.when(
      data: (movie) => _DetailView(movie: movie),
      loading: () => const _MovieDetailSkeleton(),
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
  final _reviewController = TextEditingController();
  final _reviewFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _reviewFocusNode.addListener(() {
      if (!_reviewFocusNode.hasFocus) {
        final text = _reviewController.text.trim();
        ref.read(listsProvider.notifier).updateReview(
              widget.movie.id,
              text.isEmpty ? null : text,
            );
      }
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _reviewFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initUserRating();
    _syncGenreIds();
  }

  void _initUserRating() {
    final watched = ref.read(listsProvider)[ListType.watched] ?? [];
    final item = watched.cast<UserListItem?>().firstWhere(
      (e) => e!.mediaId == widget.movie.id,
      orElse: () => null,
    );
    final saved = item?.userRating;
    if (saved != null && saved > 0) {
      // userRating is stored 0–10; RatingBar uses 0–5 half-star scale
      setState(() => _userRating = saved / 2);
    }
    if (_reviewController.text.isEmpty && item?.review != null) {
      _reviewController.text = item!.review!;
    }
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

    final bgImageUrl = movie.hasBackdrop
        ? AppConstants.backdropUrl(movie.backdropPath!)
        : movie.hasPoster
            ? AppConstants.posterUrl(movie.posterPath!, size: AppConstants.posterW500)
            : null;

    final imageCover = Stack(
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
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.transparent, Color(0xFF000000)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );

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

                _buildRatingSection(context, movie, listNotifier),
                const SizedBox(height: 24),

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

                if ((movie.budget != null && movie.budget! > 0) ||
                    (movie.revenue != null && movie.revenue! > 0)) ...[
                  _buildSection(
                    context,
                    title: 'Box Office',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          if (movie.budget != null && movie.budget! > 0)
                            Expanded(
                              child: _BoxOfficeCard(
                                label: 'Budget',
                                value: _formatCurrency(movie.budget!),
                                icon: Icons.payments_outlined,
                              ),
                            ),
                          if (movie.budget != null && movie.budget! > 0 &&
                              movie.revenue != null && movie.revenue! > 0)
                            const SizedBox(width: 12),
                          if (movie.revenue != null && movie.revenue! > 0)
                            Expanded(
                              child: _BoxOfficeCard(
                                label: 'Revenue',
                                value: _formatCurrency(movie.revenue!),
                                icon: Icons.trending_up_rounded,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

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

                ref.watch(movieVideosProvider(movie.id)).when(
                  data: (videos) => videos.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              context,
                              title: 'Trailers',
                              child: SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: videos.length,
                                  itemBuilder: (ctx, i) {
                                    final video = videos[i];
                                    final key = video['key'] as String;
                                    final name = video['name'] as String? ?? 'Trailer';
                                    final type = video['type'] as String? ?? '';
                                    final thumbUrl =
                                        'https://img.youtube.com/vi/$key/hqdefault.jpg';
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          right: i < videos.length - 1 ? 14 : 0),
                                      child: GestureDetector(
                                        onTap: () async {
                                          // Validate YouTube video ID format to prevent URL injection
                                          if (!RegExp(r'^[a-zA-Z0-9_-]{1,20}$').hasMatch(key)) return;
                                          final uri = Uri.parse(
                                              'https://www.youtube.com/watch?v=$key');
                                          await launchUrl(uri,
                                              mode: LaunchMode.externalApplication);
                                        },
                                        child: SizedBox(
                                          width: 280,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: CachedNetworkImage(
                                                  imageUrl: thumbUrl,
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, _) => Container(
                                                    color: AppThemeColors.of(context)
                                                        .surfaceVariant,
                                                  ),
                                                  errorWidget: (ctx, e, _) =>
                                                      Container(
                                                    color: AppThemeColors.of(ctx)
                                                        .surfaceVariant,
                                                  ),
                                                ),
                                              ),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Container(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.35),
                                                ),
                                              ),
                                              Center(
                                                child: Container(
                                                  width: 52,
                                                  height: 52,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppColors.primary
                                                            .withValues(alpha: 0.5),
                                                        blurRadius: 16,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.play_arrow_rounded,
                                                    color: Colors.black,
                                                    size: 30,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                left: 12,
                                                right: 12,
                                                bottom: 12,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        shadows: [
                                                          Shadow(
                                                              color: Colors.black,
                                                              blurRadius: 8)
                                                        ],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (type.isNotEmpty)
                                                      Text(
                                                        type,
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withValues(alpha: 0.7),
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                  ],
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
                            const SizedBox(height: 24),
                          ],
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, e) => const SizedBox.shrink(),
                ),

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
        ],
      ),
    );
  }

  Widget _buildMainInfo(BuildContext context, MovieDetail movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                if (movie.directors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Directed by ${movie.directors.join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeColors.of(context).textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                RatingBadge(rating: movie.voteAverage, fontSize: 14, iconSize: 16, showBackground: false),
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
                ? Icons.visibility
                : Icons.visibility_outlined,
            label: 'Watched',
            active: isWatched,
            activeColor: AppColors.success,
            onTap: () {
              if (!ref.read(isSignedInProvider)) {
                _requireSignIn(context);
                return;
              }
              listNotifier.toggleWatched(movieAsMovie,
                  runtime: movie.runtime,
                  genreIds: movie.genres.map((g) => g.id).toList());
            },
          ),
          const SizedBox(width: 12),
          _RoundActionBtn(
            icon: isWatchLater
                ? Icons.access_time_rounded
                : Icons.access_time_outlined,
            label: 'Watch Later',
            active: isWatchLater,
            activeColor: AppColors.primary,
            onTap: () {
              if (!ref.read(isSignedInProvider)) {
                _requireSignIn(context);
                return;
              }
              listNotifier.toggleWatchLater(movieAsMovie);
            },
          ),
          const SizedBox(width: 12),
          _RoundActionBtn(
            icon: Icons.thumb_up_rounded,
            label: 'Recommend',
            active: false,
            activeColor: AppColors.warning,
            onTap: () => _shareRecommendation(context, movie),
          ),
          const SizedBox(width: 12),
          _RoundActionBtn(
            icon: Icons.playlist_add_rounded,
            label: 'Add to List',
            active: false,
            activeColor: AppColors.primary,
            onTap: () {
              if (!ref.read(isSignedInProvider)) {
                _requireSignIn(context);
                return;
              }
              _showAddToListSheet(context, movie);
            },
          ),
        ],
      ),
    );
  }

  void _showAddToListSheet(BuildContext context, MovieDetail movie) {
    final movieAsItem = UserListItem(
      mediaId: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      listType: ListType.custom,
      mediaType: 'movie',
      addedAt: DateTime.now(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddToListSheet(item: movieAsItem),
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
                if (!ref.read(isSignedInProvider)) {
                  _requireSignIn(context);
                  return;
                }
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
                'Your rating: ${_userRating == _userRating.roundToDouble() ? _userRating.toInt() : _userRating.toStringAsFixed(1)} / 5',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _reviewController,
                focusNode: _reviewFocusNode,
                maxLength: 140,
                maxLines: 3,
                minLines: 1,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'What did you think? (optional)',
                  counterStyle: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showShareSheet(context, movie),
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

  void _showShareSheet(BuildContext context, MovieDetail movie) {
    if (!ref.read(isSignedInProvider)) {
      _requireSignIn(context);
      return;
    }
    final user = ref.read(currentUserProvider);
    final username = (user?.userMetadata?['full_name'] as String?) ??
        user?.email?.split('@').first;
    final posterUrl = movie.hasBackdrop
        ? AppConstants.backdropUrl(movie.backdropPath!, size: AppConstants.backdropW1280)
        : movie.hasPoster
            ? AppConstants.posterUrl(movie.posterPath!, size: AppConstants.posterOriginal)
            : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareRatingSheet(
        title: movie.title,
        year: movie.year,
        posterUrl: posterUrl,
        rating: _userRating,
        username: username,
        review: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        mediaId: movie.id,
        mediaType: 'movie',
      ),
    );
  }

  void _shareRecommendation(BuildContext context, MovieDetail movie) {
    final posterUrl = movie.hasPoster
        ? AppConstants.posterUrl(movie.posterPath!, size: AppConstants.posterW500)
        : movie.hasBackdrop
            ? AppConstants.backdropUrl(movie.backdropPath!)
            : null;
    final user = ref.read(currentUserProvider);
    final username = (user?.userMetadata?['full_name'] as String?) ??
        user?.email?.split('@').first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecommendShareSheet(
        title: movie.title,
        year: movie.year,
        posterUrl: posterUrl,
        username: username,
      ),
    );
  }

  void _requireSignIn(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sign in to add films to your lists',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000000) return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    if (amount >= 1000000) return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '\$${(amount / 1000).toStringAsFixed(1)}K';
    return '\$$amount';
  }
}

class _BoxOfficeCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BoxOfficeCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: colors.textMuted),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 18, color: colors.textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
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
                    color: active ? activeColor.withValues(alpha: 0.4) : colors.border.withValues(alpha: 0.5),
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
                        fontSize: 9,
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

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _MovieDetailSkeleton extends StatelessWidget {
  const _MovieDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Shimmer.fromColors(
        baseColor: colors.surfaceVariant,
        highlightColor: colors.border,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image
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
                          const SizedBox(height: 6),
                          _SBox(h: 22, w: 160),
                          const SizedBox(height: 14),
                          Row(children: [
                            _SBox(w: 76, h: 26, r: 8),
                            const SizedBox(width: 8),
                            _SBox(w: 68, h: 26, r: 8),
                          ]),
                          const SizedBox(height: 10),
                          _SBox(w: 100, h: 20, r: 6),
                          const SizedBox(height: 8),
                          _SBox(w: 70, h: 13, r: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4 action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(child: _SBox(h: 58, r: 14)),
                  const SizedBox(width: 12),
                  Expanded(child: _SBox(h: 58, r: 14)),
                  const SizedBox(width: 12),
                  Expanded(child: _SBox(h: 58, r: 14)),
                  const SizedBox(width: 12),
                  Expanded(child: _SBox(h: 58, r: 14)),
                ]),
              ),
              const SizedBox(height: 28),

              // Overview
              _SkeletonSection(
                titleWidth: 80,
                lines: const [null, null, 200],
              ),
              const SizedBox(height: 28),

              // Rate this movie
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SBox(w: 140, h: 16, r: 4),
                    const SizedBox(height: 14),
                    Row(children: List.generate(5, (i) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _SBox(w: 36, h: 36, r: 18),
                    ))),
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

              // Cast
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SBox(w: 50, h: 16, r: 4),
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
              const SizedBox(height: 28),

              // Trailers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SBox(w: 70, h: 16, r: 4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 14 : 0),
                    child: _SBox(w: 280, h: 180, r: 14),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // More Like This
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SBox(w: 120, h: 16, r: 4),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 195,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 14 : 0),
                    child: _SBox(w: 120, h: 195, r: 12),
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

/// Solid white placeholder box — Shimmer.fromColors animates the color.
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

class _SkeletonSection extends StatelessWidget {
  final double titleWidth;
  final List<double?> lines; // null = full width
  const _SkeletonSection({required this.titleWidth, required this.lines});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SBox(w: titleWidth, h: 16, r: 4),
            const SizedBox(height: 12),
            ...lines.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SBox(w: w, h: 13, r: 4),
                )),
          ],
        ),
      );
}
