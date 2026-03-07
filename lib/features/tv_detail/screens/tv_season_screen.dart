import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/tv_detail.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';

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

    return Scaffold(
      backgroundColor: AppThemeColors.of(context).background,
      body: seasonAsync.when(
        data: (season) => _SeasonView(
          season: season,
          showTitle: showTitle,
          tvId: tvId,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, s) => Center(
          child: Text('Failed to load season',
              style: TextStyle(
                  color: AppThemeColors.of(context).textSecondary)),
        ),
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
            (ctx, i) => _EpisodeTile(episode: season.episodes[i]),
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

// ── Episode Tile ──────────────────────────────────────────────────────────────

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  const _EpisodeTile({required this.episode});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Still image
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
                // Info
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
          ],
        ),
      ),
    );
  }
}
