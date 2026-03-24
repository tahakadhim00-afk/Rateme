import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/tv_detail.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../movie_detail/widgets/share_rating_sheet.dart';

class TvSeasonScreen extends ConsumerWidget {
  final int tvId;
  final int seasonNumber;

  const TvSeasonScreen({
    super.key,
    required this.tvId,
    required this.seasonNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync =
        ref.watch(tvSeasonDetailProvider((tvId, seasonNumber)));
    final showAsync = ref.watch(tvDetailProvider(tvId));

    final showTitle = showAsync.valueOrNull?.title ?? '';

    final show = showAsync.valueOrNull;
    final bgImageUrl = show != null
        ? (show.hasBackdrop
            ? AppConstants.backdropUrl(show.backdropPath!)
            : show.hasPoster
                ? AppConstants.posterUrl(show.posterPath!, size: AppConstants.posterW500)
                : null)
        : null;

    return Scaffold(
      backgroundColor: AppThemeColors.of(context).background,
      body: Stack(
        children: [
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
          seasonAsync.when(
            data: (season) => _SeasonView(
              season: season,
              showTitle: showTitle,
              tvId: tvId,
            ),
            loading: () => const _SeasonSkeleton(),
            error: (e, s) => Center(
              child: Text('Failed to load season',
                  style: TextStyle(
                      color: AppThemeColors.of(context).textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonView extends StatelessWidget {
  final TvSeasonDetail season;
  final String showTitle;
  final int tvId;

  const _SeasonView({
    required this.season,
    required this.showTitle,
    required this.tvId,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(child: _buildSeasonHeader(context)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _EpisodeTile(
              episode: season.episodes[i],
              showTitle: showTitle,
            ),
            childCount: season.episodes.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppThemeColors.of(context).surface,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppThemeColors.of(context).surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_back_ios_rounded,
              color: AppThemeColors.of(context).textPrimary, size: 20),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle.isNotEmpty)
            Text(
              showTitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppThemeColors.of(context).textMuted,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            season.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonHeader(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (season.hasPoster)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: AppConstants.posterUrl(season.posterPath!),
                width: 90,
                height: 134,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tv_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${season.episodes.length} episode${season.episodes.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                if (season.airDate?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: colors.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        season.airDate!.length >= 4
                            ? season.airDate!.substring(0, 4)
                            : season.airDate!,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ],
                if (season.overview?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    season.overview!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          height: 1.5,
                        ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _SeasonSkeleton extends StatelessWidget {
  const _SeasonSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Shimmer.fromColors(
        baseColor: colors.surfaceVariant,
        highlightColor: colors.border,
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            // App bar placeholder
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.surface,
              automaticallyImplyLeading: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 10, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
                  Container(width: 160, height: 14, color: Colors.white),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 90, height: 134, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 120, height: 14, color: Colors.white),
                          const SizedBox(height: 10),
                          Container(width: 80, height: 12, color: Colors.white),
                          const SizedBox(height: 10),
                          Container(height: 12, color: Colors.white),
                          const SizedBox(height: 6),
                          Container(height: 12, color: Colors.white),
                          const SizedBox(height: 6),
                          Container(width: 140, height: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 60, height: 12, color: Colors.white),
                              const SizedBox(height: 8),
                              Container(height: 12, color: Colors.white),
                              const SizedBox(height: 6),
                              Container(width: 120, height: 12, color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
                childCount: 6,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Episode Tile ──────────────────────────────────────────────────────────────

class _EpisodeTile extends ConsumerStatefulWidget {
  final Episode episode;
  final String showTitle;

  const _EpisodeTile({
    required this.episode,
    required this.showTitle,
  });

  @override
  ConsumerState<_EpisodeTile> createState() => _EpisodeTileState();
}

class _EpisodeTileState extends ConsumerState<_EpisodeTile> {
  double _userRating = 0;

  void _requireSignIn() {
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

  void _showShareSheet() {
    if (!ref.read(isSignedInProvider)) {
      _requireSignIn();
      return;
    }
    final user = ref.read(currentUserProvider);
    final username = (user?.userMetadata?['full_name'] as String?) ??
        user?.email?.split('@').first;
    final episode = widget.episode;
    final posterUrl = episode.hasStill
        ? AppConstants.posterUrl(episode.stillPath!, size: AppConstants.posterOriginal)
        : null;
    final episodeTitle =
        'S${episode.episodeNumber.toString().padLeft(2, '0')} · ${episode.name}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareRatingSheet(
        title: episodeTitle,
        year: episode.year,
        posterUrl: posterUrl,
        rating: _userRating,
        username: username,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final episode = widget.episode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: episode.hasStill
                      ? CachedNetworkImage(
                          imageUrl: AppConstants.posterUrl(
                            episode.stillPath!,
                            size: '/w300',
                          ),
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 120,
                          height: 80,
                          color: colors.surfaceVariant,
                          child: Icon(Icons.play_circle_outline_rounded,
                              color: colors.textMuted, size: 32),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'E${episode.episodeNumber.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (episode.runtimeFormatted.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.schedule_rounded,
                                  size: 11, color: colors.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                episode.runtimeFormatted,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (episode.voteAverage > 0) ...[
                              const Spacer(),
                              const Icon(Icons.star_rounded,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text(
                                episode.voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          episode.name,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (episode.overview?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  episode.overview!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ── Rating section ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  RatingBar.builder(
                    initialRating: _userRating,
                    minRating: 0.5,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 26,
                    itemPadding:
                        const EdgeInsets.symmetric(horizontal: 2),
                    itemBuilder: (ctx, _) => const Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                    ),
                    onRatingUpdate: (r) {
                      if (!ref.read(isSignedInProvider)) {
                        _requireSignIn();
                        return;
                      }
                      setState(() => _userRating = r);
                    },
                  ),
                  if (_userRating > 0) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showShareSheet,
                        icon: const Icon(Icons.ios_share_rounded, size: 15),
                        label: const Text('Share Rating'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.primary, width: 1),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
