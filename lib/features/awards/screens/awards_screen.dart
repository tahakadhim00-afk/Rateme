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
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(awardsListProvider),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Safe area top ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top),
            ),

            // ── Hero Header ──────────────────────────────────────────────
            const SliverToBoxAdapter(child: _AwardsHero()),

            // ── Award cards ──────────────────────────────────────────────
            awardsAsync.when(
              loading: () => _buildSkeletonList(colors),
              error: (_, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline,
                          color: colors.textMuted, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load awards.\nPull to retry.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: colors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              data: (awards) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                sliver: SliverList.builder(
                  itemCount: awards.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AnimatedAwardCard(
                      award: awards[i],
                      index: i,
                      onTap: () => ctx.push('/award/${awards[i].id}'),
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

  SliverPadding _buildSkeletonList(AppThemeColors colors) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList.separated(
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => Shimmer.fromColors(
          baseColor: colors.surfaceVariant,
          highlightColor: const Color(0xFF2A2520),
          child: Container(
            height: 80,
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

// ── Hero Header ────────────────────────────────────────────────────────────────

class _AwardsHero extends StatelessWidget {
  const _AwardsHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Row(
            children: [
              Container(width: 18, height: 1.5, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'FILM & TELEVISION',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 18, height: 1.5, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 14),

          // Logo + title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App logo
              Image.asset(
                'assets/logo_and_images/app_bar.png',
                height: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),

              // Title stack
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AWARDS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      height: 0.9,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFD84D),
                        Color(0xFFFEC720),
                        Color(0xFFD4A800),
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'SEASON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gradient divider
          Container(
            height: 1,
            width: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Tap any ceremony to explore\nits winners & nominees',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Award Card ────────────────────────────────────────────────────────

class _AnimatedAwardCard extends StatefulWidget {
  final Award award;
  final int index;
  final VoidCallback onTap;

  const _AnimatedAwardCard({
    required this.award,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedAwardCard> createState() => _AnimatedAwardCardState();
}

class _AnimatedAwardCardState extends State<_AnimatedAwardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(
      Duration(milliseconds: 60 + widget.index * 50),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: _AwardCard(award: widget.award),
          ),
        ),
      ),
    );
  }
}

// ── Award Card ─────────────────────────────────────────────────────────────────

class _AwardCard extends StatelessWidget {
  final Award award;
  const _AwardCard({required this.award});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final year = _extractYear(award.latestCeremonyDate);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF131210),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          // Gold vertical accent bar
          Container(
            width: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFDE6E),
                  Color(0xFFFEC720),
                  Color(0xFFB88A00),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Logo
          _CardLogo(award: award),

          const SizedBox(width: 14),

          // Text info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  award.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (award.originCountry != null) ...[
                      Text(
                        award.originCountry!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (award.latestCeremonyDate != null)
                        Text(
                          '  ·  ',
                          style: TextStyle(
                              color: colors.textMuted, fontSize: 11),
                        ),
                    ],
                    if (award.latestCeremonyDate != null)
                      Text(
                        _formatDate(award.latestCeremonyDate!),
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Year badge or arrow
          if (year != null)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              child: Text(
                year.toString(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            )
          else ...[
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textMuted.withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }

  int? _extractYear(String? date) {
    if (date == null) return null;
    try {
      return DateTime.parse(date).year;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(String raw) {
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

// ── Card Logo ──────────────────────────────────────────────────────────────────

class _CardLogo extends StatelessWidget {
  final Award award;
  const _CardLogo({required this.award});

  @override
  Widget build(BuildContext context) {
    Widget logoWidget;

    if (award.hasLocalAsset) {
      logoWidget = Image.asset(
        award.assetPath!,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _trophy(),
      );
    } else if (award.hasLogo) {
      logoWidget = Image.network(
        award.logoUrl(size: 'h90')!,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _trophy(),
      );
    } else {
      logoWidget = _trophy();
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: logoWidget),
    );
  }

  Widget _trophy() =>
      const Text('🏆', style: TextStyle(fontSize: 22));
}
