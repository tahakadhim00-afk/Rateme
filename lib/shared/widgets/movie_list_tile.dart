import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_list_item.dart';
import '../../core/theme/app_theme.dart';
import 'rating_badge.dart';

class MovieListTile extends StatelessWidget {
  final UserListItem item;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const MovieListTile({
    super.key,
    required this.item,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Row(
          children: [
            _buildPoster(context),
            const SizedBox(width: 14),
            Expanded(child: _buildInfo(context)),
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.close_rounded,
                      color: colors.textMuted, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 60,
        height: 88,
        child: item.posterPath != null
            ? CachedNetworkImage(
                imageUrl: AppConstants.posterUrl(item.posterPath!),
                fit: BoxFit.cover,
                errorWidget: (_, e, s) => _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      color: colors.surfaceVariant,
      child: Icon(Icons.movie_outlined, color: colors.textMuted, size: 24),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (item.year.isNotEmpty)
              Text(item.year,
                  style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 10),
            RatingBadge(rating: item.voteAverage),
          ],
        ),
        if (item.userRating != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 12),
              const SizedBox(width: 4),
              Text(
                'Your rating: ${item.userRating!.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
