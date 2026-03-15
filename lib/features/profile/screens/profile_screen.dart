import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../../../core/constants/app_constants.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/cover_provider.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/models/genre.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/google_sign_in_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(watchedProvider);
    final watchLater = ref.watch(watchLaterProvider);
    final isLoading = ref.watch(listsLoadingProvider);
    final authState = ref.watch(authNotifierProvider);
    final User? user = ref.watch(currentUserProvider);
    final isSignedIn = user != null;
    final coverUrl = ref.watch(coverProvider);

    final displayName = isSignedIn
        ? ((user.userMetadata?['full_name'] as String?) ?? user.email ?? 'Signed In')
        : 'Guest User';
    final email = isSignedIn ? (user.email ?? '') : '';
    final avatarUrl = isSignedIn ? (user.userMetadata?['avatar_url'] as String?) : null;

    final movies = watched.where((e) => e.mediaType == 'movie').toList();
    final tvShows = watched.where((e) => e.mediaType == 'tv').toList();

    final ratings = watched.where((e) => e.userRating != null).toList();
    final avgRating = ratings.isEmpty
        ? null
        : ratings.fold(0.0, (s, e) => s + e.userRating!) / ratings.length;

    final colors = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // ── Blurry cover background ────────────────────────────────────────
          if (coverUrl != null) ...[
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(color: colors.background.withValues(alpha: 0.75)),
            ),
          ],

          // ── Content ───────────────────────────────────────────────────────
          isSignedIn
              ? CustomScrollView(
                  slivers: [
                    // ── Cinematic Header ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _buildHeader(
                        context: context,
                        ref: ref,
                        coverUrl: coverUrl,
                        avatarUrl: avatarUrl,
                        displayName: displayName,
                        email: email,
                        isSignedIn: isSignedIn,
                        authLoading: authState.isLoading,
                        colors: colors,
                      ),
                    ),

                    // ── Stats ────────────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: isLoading
                            ? _shimmerBox(context, 220)
                            : _buildStatsSection(
                                context,
                                watched.length,
                                watchLater.length,
                                avgRating,
                                movies,
                                tvShows,
                              ),
                      ),
                    ),

                    // ── Genre Chart ───────────────────────────────────────────────
                    if (!isLoading && watched.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: _buildGenreChart(context, watched),
                        ),
                      ),

                    if (isLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: _shimmerBox(context, 200),
                        ),
                      ),

                    // ── Settings ─────────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                        child: _SettingsCard(isSignedIn: isSignedIn),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  ],
                )
              : _buildGuestView(context, ref, authState.isLoading, colors),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildGuestView(
    BuildContext context,
    WidgetRef ref,
    bool loading,
    AppThemeColors colors,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Image.asset(
              'assets/logo_and_images/app_bar.png',
              width: 72,
              height: 72,
            ),
            const SizedBox(height: 24),
            Text(
              'Your Profile',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to track your watched films, rate shows, and sync your lists across devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            GoogleSignInButton(
              loading: loading,
              onTap: () =>
                  ref.read(authNotifierProvider.notifier).signInWithGoogle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required WidgetRef ref,
    required String? coverUrl,
    required String? avatarUrl,
    required String displayName,
    required String email,
    required bool isSignedIn,
    required bool authLoading,
    required AppThemeColors colors,
  }) {
    return Column(
      children: [
        // ── Cover image ──────────────────────────────────────────────────────
        Stack(
          children: [
            GestureDetector(
              onTap: () => _showCoverPicker(context, ref),
              child: SizedBox(
                width: double.infinity,
                height: 240,
                child: coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _coverFallback(colors),
                      )
                    : _coverFallback(colors),
              ),
            ),
            // Top gradient for status bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Edit cover button
            Positioned(
              top: 52,
              right: 16,
              child: GestureDetector(
                onTap: () => _showCoverPicker(context, ref),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Edit Cover',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── Avatar + info ────────────────────────────────────────────────────
        Transform.translate(
          offset: const Offset(0, -48),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _avatarFallback(),
                          )
                        : _avatarFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              if (!isSignedIn) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GoogleSignInButton(
                    loading: authLoading,
                    onTap: () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.person_rounded, color: Colors.black54, size: 48),
      );

  Widget _coverFallback(AppThemeColors colors) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.surface, colors.surfaceVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(Icons.image_outlined, size: 40, color: colors.textMuted),
        ),
      );

  // ── Stats Section (unified) ───────────────────────────────────────────────

  Widget _buildStatsSection(
    BuildContext context,
    int watchedCount,
    int watchLaterCount,
    double? avgRating,
    List<UserListItem> movies,
    List<UserListItem> tvShows,
  ) {
    final colors = AppThemeColors.of(context);

    int minutesFor(List<UserListItem> items) =>
        items.where((e) => e.runtime != null).fold(0, (s, e) => s + e.runtime!);

    String fmtTime(int mins) {
      if (mins == 0) return '—';
      final d = mins ~/ (60 * 24);
      final h = (mins % (60 * 24)) ~/ 60;
      final m = mins % 60;
      if (d > 0) return '${d}d ${h}h';
      if (h > 0) return '${h}h ${m}m';
      return '${m}m';
    }

    final movieMins = minutesFor(movies);
    final tvMins = minutesFor(tvShows);
    final totalMins = movieMins + tvMins;
    final total = movies.length + tvShows.length;
    final movieRatio = total == 0 ? 0.5 : movies.length / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: colors.border.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.insights_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Your Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 3 main stats
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        value: watchedCount.toString(),
                        label: 'Watched',
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    VerticalDivider(
                        color: colors.border.withValues(alpha: 0.5),
                        width: 1),
                    Expanded(
                      child: _StatItem(
                        value: watchLaterCount.toString(),
                        label: 'Watchlist',
                        icon: Icons.bookmark_rounded,
                      ),
                    ),
                    VerticalDivider(
                        color: colors.border.withValues(alpha: 0.5),
                        width: 1),
                    Expanded(
                      child: _StatItem(
                        value: avgRating != null
                            ? avgRating.toStringAsFixed(1)
                            : '—',
                        label: 'Avg Rating',
                        imagePath: 'assets/app_icons/star.png',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(
                  color: colors.border.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: 20),

              // Films vs TV counts
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.movie_rounded,
                              size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movies.length.toString(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Films',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              tvShows.length.toString(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'TV Shows',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tv_rounded,
                              size: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Split bar
              if (total > 0) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      FractionallySizedBox(
                        widthFactor: movieRatio,
                        child: Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(movieRatio * 100).round()}% Films',
                      style: TextStyle(color: colors.textMuted, fontSize: 10),
                    ),
                    Text(
                      '${((1 - movieRatio) * 100).round()}% TV',
                      style: TextStyle(color: colors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],

              // Watch time breakdown
              if (totalMins > 0) ...[
                const SizedBox(height: 16),
                // Films + TV time side by side
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: colors.border.withValues(alpha: 0.5), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.movie_rounded,
                                  size: 15, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Films',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  movieMins > 0 ? fmtTime(movieMins) : '—',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: colors.border.withValues(alpha: 0.5), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.tv_rounded,
                                  size: 15, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TV Shows',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tvMins > 0 ? fmtTime(tvMins) : '—',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Total time full-width
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: colors.border.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.av_timer_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Watch Time',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fmtTime(totalMins),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Genre Chart ───────────────────────────────────────────────────────────

  Widget _buildGenreChart(BuildContext context, List<UserListItem> watched) {
    final tally = <int, int>{};
    for (final item in watched) {
      for (final id in item.genreIds) {
        tally[id] = (tally[id] ?? 0) + 1;
      }
    }
    if (tally.isEmpty) return const SizedBox.shrink();

    final sorted = tally.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sorted.take(8).toList();
    final maxCount = topEntries.first.value;
    final colors = AppThemeColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Genre Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...topEntries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GenreBar(
                      name: kGenreNames[entry.key] ?? 'Other',
                      count: entry.value,
                      ratio: entry.value / maxCount,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Settings Card ─────────────────────────────────────────────────────────

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _shimmerBox(BuildContext context, double height) {
    final c = AppThemeColors.of(context);
    return Shimmer.fromColors(
      baseColor: c.surfaceVariant,
      highlightColor: c.card,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _showCoverPicker(BuildContext context, WidgetRef ref) {
    if (!ref.read(isSignedInProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sign in to set a profile cover',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoverPickerSheet(parentRef: ref),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SettingsCard extends ConsumerStatefulWidget {
  final bool isSignedIn;
  const _SettingsCard({required this.isSignedIn});

  @override
  ConsumerState<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends ConsumerState<_SettingsCard> {
  bool _reminderEnabled = false;

  @override
  void initState() {
    super.initState();
    NotificationService.isReminderEnabled().then((v) {
      if (mounted) setState(() => _reminderEnabled = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: colors.border.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.info_outline_rounded,
                iconBg: const Color(0xFF3A7BF7),
                label: 'About RateMe',
                onTap: () => _showAbout(context),
              ),
              Divider(height: 1, color: colors.border.withValues(alpha: 0.4)),
              // Daily reminder toggle
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF30D158).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          size: 18, color: Color(0xFF30D158)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Daily Reminder',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _reminderEnabled,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                      onChanged: (val) async {
                        await NotificationService.setReminderEnabled(val);
                        if (mounted) setState(() => _reminderEnabled = val);
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border.withValues(alpha: 0.4)),
              if (!widget.isSignedIn)
                _SettingRow(
                  icon: Icons.login_rounded,
                  iconBg: AppColors.primary,
                  iconColor: Colors.black,
                  label: 'Sign In / Create Account',
                  labelColor: AppColors.primary,
                  onTap: () => context.go('/signin'),
                )
              else ...[
                _SettingRow(
                  icon: Icons.logout_rounded,
                  iconBg: AppColors.error,
                  label: 'Sign Out',
                  labelColor: AppColors.error,
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    ref.read(listsProvider.notifier).clearAll();
                    if (context.mounted) context.go('/signin');
                  },
                ),
                Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
                _SettingRow(
                  icon: Icons.delete_forever_rounded,
                  iconBg: AppColors.error,
                  label: 'Delete Account',
                  labelColor: AppColors.error,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = AppThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: colors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Image.asset('assets/logo_and_images/app_bar.png',
                  width: 36, height: 36),
              const SizedBox(width: 12),
              Text('RateMe', style: TextStyle(color: colors.textPrimary)),
            ],
          ),
          content: Text(
            'RateMe is the first Iraqi app dedicated to rating movies and TV shows. Powered by TMDb.',
            style: TextStyle(color: colors.textSecondary, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          title: Text(
            'Delete Account',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently delete your account and all your data (ratings, watchlists, favorites). This action cannot be undone.',
                style: TextStyle(color: colors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Type "Rate Me" to confirm:',
                style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                cursorColor: AppColors.error,
                decoration: InputDecoration(
                  hintText: 'Rate Me',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: colors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: ctrl.text == 'Rate Me'
                  ? () async {
                      Navigator.pop(ctx);
                      await _deleteAccount();
                    }
                  : null,
              child: Text(
                'Delete',
                style: TextStyle(
                  color: ctrl.text == 'Rate Me' ? AppColors.error : colors.textSecondary.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // Clear local SharedPreferences data for this user
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_cover_url_${user.id}');
      await prefs.remove('custom_lists_v1_${user.id}');

      // Clear in-memory list state
      ref.read(listsProvider.notifier).clearAll();

      // Delete account and all DB data
      await ref.read(authNotifierProvider.notifier).deleteAccount();

      if (mounted) context.go('/signin');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final String? imagePath;

  const _StatItem({
    required this.value,
    required this.label,
    this.icon,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imagePath != null)
          Image.asset(imagePath!, width: 18, height: 18, color: AppColors.primary)
        else
          Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _GenreBar extends StatelessWidget {
  final String name;
  final int count;
  final double ratio;

  const _GenreBar({required this.name, required this.count, required this.ratio});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            name,
            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.iconBg,
    this.iconColor = Colors.white,
    required this.label,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Cover Picker Sheet ────────────────────────────────────────────────────────

class _CoverPickerSheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _CoverPickerSheet({required this.parentRef});

  @override
  ConsumerState<_CoverPickerSheet> createState() => _CoverPickerSheetState();
}

class _CoverPickerSheetState extends ConsumerState<_CoverPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Movie> _results = [];
  List<String> _backdrops = [];
  bool _loading = false;
  bool _showingBackdrops = false;
  Movie? _selectedMovie;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await ref.read(tmdbServiceProvider).searchMulti(query.trim());
      setState(() => _results = results);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadBackdrops(Movie movie) async {
    setState(() {
      _loading = true;
      _selectedMovie = movie;
      _showingBackdrops = true;
      _backdrops = [];
    });
    try {
      final paths = await ref.read(tmdbServiceProvider).getBackdrops(movie.id, movie.mediaType);
      setState(() => _backdrops = paths);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  void _pickBackdrop(String path) {
    final url = AppConstants.backdropUrl(path, size: AppConstants.backdropW780);
    widget.parentRef.read(coverProvider.notifier).setCover(url);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
            child: Row(
              children: [
                if (_showingBackdrops)
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
                    onPressed: () => setState(() {
                      _showingBackdrops = false;
                      _backdrops = [];
                      _selectedMovie = null;
                    }),
                  )
                else
                  const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _showingBackdrops ? (_selectedMovie?.title ?? 'Pick a backdrop') : 'Choose Cover',
                    style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),
          if (!_showingBackdrops)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search movies or TV shows…',
                  hintStyle: TextStyle(color: colors.textMuted),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted),
                  filled: true,
                  fillColor: colors.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _search,
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _showingBackdrops
                    ? _buildBackdropGrid(colors)
                    : _buildSearchResults(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AppThemeColors colors) {
    if (_results.isEmpty) {
      return Center(
        child: Text(
          _searchCtrl.text.isEmpty ? 'Search for a title to pick a cover' : 'No results found',
          style: TextStyle(color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final movie = _results[i];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: movie.posterPath != null
                ? CachedNetworkImage(
                    imageUrl: AppConstants.posterUrl(movie.posterPath!, size: AppConstants.posterW342),
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _posterFallback(colors),
                  )
                : _posterFallback(colors),
          ),
          title: Text(movie.title,
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${movie.mediaType == 'tv' ? 'TV Show' : 'Movie'}${movie.year.isNotEmpty ? ' · ${movie.year}' : ''}',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          onTap: () => _loadBackdrops(movie),
        );
      },
    );
  }

  Widget _posterFallback(AppThemeColors colors) => Container(
        width: 40,
        height: 60,
        decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
        child: Icon(Icons.movie_rounded, size: 20, color: colors.textMuted),
      );

  Widget _buildBackdropGrid(AppThemeColors colors) {
    if (_backdrops.isEmpty) {
      return Center(
        child: Text(
          'No backdrops available for this title',
          style: TextStyle(color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 16 / 9,
      ),
      itemCount: _backdrops.length,
      itemBuilder: (context, i) {
        final url = AppConstants.backdropUrl(_backdrops[i], size: AppConstants.backdropW780);
        return GestureDetector(
          onTap: () => _pickBackdrop(_backdrops[i]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: colors.surfaceVariant),
              errorWidget: (_, _, _) => Container(
                color: colors.surfaceVariant,
                child: Icon(Icons.broken_image_outlined, color: colors.textMuted),
              ),
            ),
          ),
        );
      },
    );
  }
}
