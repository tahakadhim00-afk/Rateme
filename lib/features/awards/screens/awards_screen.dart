import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/models/award.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';

class AwardsScreen extends ConsumerWidget {
  const AwardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppThemeColors.of(context);
    final awardsAsync = ref.watch(awardsListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(awardsListProvider),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── App bar ───────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              scrolledUnderElevation: 0,
              elevation: 0,
              title: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    'Awards',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Subtitle ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Text(
                  'Tap any ceremony to browse its winners',
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
            ),

            // ── Award cards ───────────────────────────────────────────────
            awardsAsync.when(
              loading: () => _buildSkeletonList(colors),
              error: (_, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Could not load awards.\nPull to retry.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                ),
              ),
              data: (awards) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList.separated(
                  itemCount: awards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _AwardCard(
                    award: awards[i],
                    onTap: () => ctx.push('/award/${awards[i].id}'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildSkeletonList(AppThemeColors colors) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList.separated(
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Shimmer.fromColors(
          baseColor: colors.surfaceVariant,
          highlightColor: colors.card,
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Award card ────────────────────────────────────────────────────────────────

class _AwardCard extends StatelessWidget {
  final Award award;
  final VoidCallback onTap;

  const _AwardCard({required this.award, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border, width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Logo
                _AwardLogo(award: award),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        award.name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (award.latestCeremonyDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 11, color: colors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(award.latestCeremonyDate!),
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (award.originCountry != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          award.originCountry!,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: colors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    // raw might be "2026-03-15" or already human-readable
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Award logo widget ─────────────────────────────────────────────────────────

class _AwardLogo extends StatelessWidget {
  final Award award;
  const _AwardLogo({required this.award});

  @override
  Widget build(BuildContext context) {
    if (!award.hasLogo) return _fallback();

    if (award.hasLocalAsset) {
      return Image.asset(
        award.assetPath!,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    final url = award.logoUrl(size: 'h90');
    return SizedBox(
      width: 56,
      height: 56,
      child: Image.network(
        url!,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('🏆', style: TextStyle(fontSize: 26)),
        ),
      );
}
