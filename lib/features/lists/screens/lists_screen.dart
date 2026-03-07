import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/theme/app_theme.dart';

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watched    = ref.watch(watchedProvider);
    final watchLater = ref.watch(watchLaterProvider);
    final notifier   = ref.read(listsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('My Lists',
                  style: Theme.of(context).textTheme.displayMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${watched.length + watchLater.length} saved films',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),

            // ── Tab bar ─────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppThemeColors.of(context).surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppThemeColors.of(context).textMuted,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w400),
                tabs: [
                  _tab(Icons.check_circle_rounded,  'Watched',      watched.length),
                  _tab(Icons.bookmark_rounded,      'Watch Later',  watchLater.length),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Grid tabs ───────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _GridTab(
                    items: watched,
                    listType: ListType.watched,
                    emptyIcon: Icons.check_circle_outline_rounded,
                    emptyMessage: 'Nothing watched yet',
                    emptySubMessage: 'Mark films as watched to track them',
                    notifier: notifier,
                  ),
                  _GridTab(
                    items: watchLater,
                    listType: ListType.watchLater,
                    emptyIcon: Icons.bookmark_border_rounded,
                    emptyMessage: 'Watch later is empty',
                    emptySubMessage: 'Save films to watch them later',
                    notifier: notifier,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Tab _tab(IconData icon, String label, int count) => Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 5),
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.black,
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

// ── Grid tab ───────────────────────────────────────────────────────────────

class _GridTab extends StatelessWidget {
  final List<UserListItem> items;
  final ListType listType;
  final IconData emptyIcon;
  final String emptyMessage;
  final String emptySubMessage;
  final ListsNotifier notifier;

  const _GridTab({
    required this.items,
    required this.listType,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        message: emptyMessage,
        subMessage: emptySubMessage,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.56,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _PosterCard(
        item: items[i],
        onTap: () => ctx.push(items[i].mediaType == 'tv'
            ? '/tv/${items[i].mediaId}'
            : '/movie/${items[i].mediaId}'),
        onRemove: () => _confirmRemove(ctx, items[i]),
      ),
    );
  }

  void _confirmRemove(BuildContext context, UserListItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.of(context).surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colors = AppThemeColors.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Remove from this list?',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          notifier.removeFromList(listType, item.mediaId);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Poster card ────────────────────────────────────────────────────────────

class _PosterCard extends StatelessWidget {
  final UserListItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PosterCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onRemove,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Poster ────────────────────────────────────────────────────
            item.posterPath != null
                ? CachedNetworkImage(
                    imageUrl: AppConstants.posterUrl(item.posterPath!),
                    fit: BoxFit.cover,
                    placeholder: (ctx, __) {
                      final c = AppThemeColors.of(ctx);
                      return Shimmer.fromColors(
                        baseColor: c.surfaceVariant,
                        highlightColor: c.card,
                        child: Container(color: c.surfaceVariant),
                      );
                    },
                    errorWidget: (ctx, _, _) => _fallback(ctx),
                  )
                : _fallback(context),

            // ── Blurred info box ──────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.primary, size: 11),
                            const SizedBox(width: 2),
                            Text(
                              item.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.year.isNotEmpty) ...[
                              const SizedBox(width: 5),
                              Text(
                                item.year,
                                style: const TextStyle(
                                  color: Color(0xAAFFFFFF),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── User rating badge (top-right, blurred) ────────────────────
            if (item.userRating != null)
              Positioned(
                top: 6,
                right: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.userRating!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      color: colors.surfaceVariant,
      child: Center(
        child: Icon(Icons.movie_outlined, color: colors.textMuted, size: 32),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppThemeColors.of(context).surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: AppThemeColors.of(context).textMuted, size: 36),
            ),
            const SizedBox(height: 20),
            Text(message,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
