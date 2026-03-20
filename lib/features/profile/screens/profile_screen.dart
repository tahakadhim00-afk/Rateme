import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          if (coverUrl != null) ...[
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: Container(color: colors.background.withValues(alpha: 0.84)),
            ),
          ],
          isSignedIn
              ? FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: CustomScrollView(
                      slivers: [
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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                            child: isLoading
                                ? _shimmerBox(context, 260)
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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                            child: _SettingsCard(isSignedIn: isSignedIn),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 48)),
                      ],
                    ),
                  ),
                )
              : _buildGuestView(context, ref, authState.isLoading, colors),
        ],
      ),
    );
  }

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
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
              child: Center(
                child: Image.asset(
                  'assets/logo_and_images/app_bar.png',
                  width: 46,
                  height: 46,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Your Profile',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to track your watched films, rate shows, and sync your lists across devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 36),
            GoogleSignInButton(
              loading: loading,
              onTap: () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
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
        Stack(
          children: [
            GestureDetector(
              onTap: () => _showCoverPicker(context, ref),
              child: SizedBox(
                width: double.infinity,
                height: 260,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl != null)
                      CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _coverFallback(colors),
                      )
                    else
                      _coverFallback(colors),
                    // Bottom scrim
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 150,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, colors.background],
                          ),
                        ),
                      ),
                    ),
                    // Top scrim for status bar
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
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Edit Cover pill
            Positioned(
              top: 52,
              right: 16,
              child: GestureDetector(
                onTap: () => _showCoverPicker(context, ref),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -52),
          child: Column(
            children: [
              // Avatar with gold gradient ring + glow
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8B84B), Color(0xFFC99A2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
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
              const SizedBox(height: 14),
              Text(
                displayName,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
                textAlign: TextAlign.center,
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  email,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.3,
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
            colors: [colors.surface, const Color(0xFF111122)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 38,
            color: colors.textMuted.withValues(alpha: 0.3),
          ),
        ),
      );

  // ── Stats Section ────────────────────────────────────────────────────────────

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
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border.withValues(alpha: 0.6), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'YOUR CINEMA',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Hero watched count
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      watchedCount.toString(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 60,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -4,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'TITLES\nWATCHED',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
              ),

              // Sub-stats row
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _EditorialStat(
                        value: watchLaterCount.toString(),
                        label: 'WATCHLIST',
                        icon: Icons.bookmark_rounded,
                      ),
                    ),
                    VerticalDivider(
                      color: colors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    Expanded(
                      child: _EditorialStat(
                        value: movies.length.toString(),
                        label: 'FILMS',
                        icon: Icons.movie_rounded,
                      ),
                    ),
                    VerticalDivider(
                      color: colors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    Expanded(
                      child: _EditorialStat(
                        value: tvShows.length.toString(),
                        label: 'TV SHOWS',
                        icon: Icons.tv_rounded,
                      ),
                    ),
                    VerticalDivider(
                      color: colors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    Expanded(
                      child: _EditorialStat(
                        value: avgRating != null ? avgRating.toStringAsFixed(1) : '—',
                        label: 'AVG SCORE',
                        imagePath: 'assets/app_icons/star.png',
                      ),
                    ),
                  ],
                ),
              ),

              // Film/TV ratio bar
              if (total > 0) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Films ${(movieRatio * 100).round()}%',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'TV ${((1 - movieRatio) * 100).round()}%',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.border,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(height: 4, color: colors.border),
                            FractionallySizedBox(
                              widthFactor: movieRatio,
                              child: Container(
                                height: 4,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Watch time
              if (totalMins > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total row
                      Row(
                        children: [
                          const Icon(Icons.av_timer_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Total watch time',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            fmtTime(totalMins),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Films + TV tiles
                      Row(
                        children: [
                          if (movieMins > 0)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.movie_outlined, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Films',
                                          style: TextStyle(
                                            color: colors.textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          fmtTime(movieMins),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (movieMins > 0 && tvMins > 0) const SizedBox(width: 10),
                          if (tvMins > 0)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.tv_outlined, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TV Shows',
                                          style: TextStyle(
                                            color: colors.textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          fmtTime(tvMins),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.5,
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
                    ],
                  ),
                )
              else
                const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Genre Chart ──────────────────────────────────────────────────────────────

  static const _genreIcons = <int, IconData>{
    28:     Icons.bolt_rounded,               // Action
    12:     Icons.explore_rounded,             // Adventure
    16:     Icons.brush_rounded,               // Animation
    35:     Icons.sentiment_very_satisfied_rounded, // Comedy
    80:     Icons.local_police_rounded,        // Crime
    99:     Icons.video_camera_back_rounded,   // Documentary
    18:     Icons.theater_comedy_rounded,      // Drama
    10751:  Icons.family_restroom_rounded,     // Family
    14:     Icons.auto_awesome_rounded,        // Fantasy
    36:     Icons.account_balance_rounded,     // History
    27:     Icons.dark_mode_rounded,           // Horror
    10402:  Icons.music_note_rounded,          // Music
    9648:   Icons.search_rounded,              // Mystery
    10749:  Icons.favorite_rounded,            // Romance
    878:    Icons.rocket_launch_rounded,       // Sci-Fi
    10770:  Icons.tv_rounded,                  // TV Movie
    53:     Icons.crisis_alert_rounded,        // Thriller
    10752:  Icons.military_tech_rounded,       // War
    37:     Icons.landscape_rounded,           // Western
    10759:  Icons.bolt_rounded,               // Action & Adventure
    10762:  Icons.child_care_rounded,          // Kids
    10763:  Icons.newspaper_rounded,           // News
    10764:  Icons.live_tv_rounded,             // Reality
    10765:  Icons.rocket_launch_rounded,       // Sci-Fi & Fantasy
    10766:  Icons.spa_rounded,                 // Soap
    10767:  Icons.mic_rounded,                 // Talk
    10768:  Icons.gavel_rounded,               // War & Politics
  };

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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border.withValues(alpha: 0.6), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'TASTE PROFILE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...topEntries.asMap().entries.map((e) {
                final i = e.key;
                final genre = e.value;
                final pct = (genre.value / watched.length * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Icon(
                          _genreIcons[genre.key] ?? Icons.category_rounded,
                          size: 15,
                          color: i < 3 ? AppColors.primary : colors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kGenreNames[genre.key] ?? 'Other',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: Stack(
                          children: [
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: colors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: genre.value / maxCount,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryDark],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$pct%',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(BuildContext context, double height) {
    final c = AppThemeColors.of(context);
    return Shimmer.fromColors(
      baseColor: c.surfaceVariant,
      highlightColor: c.card,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
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

// ── Account Sheet ─────────────────────────────────────────────────────────────

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet();

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Account',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _SettingRow(
              icon: Icons.logout_rounded,
              iconBg: AppColors.error,
              label: 'Sign Out',
              labelColor: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).signOut();
                ref.read(listsProvider.notifier).clearAll();
                if (context.mounted) context.go('/signin');
              },
            ),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.4)),
            _SettingRow(
              icon: Icons.delete_forever_rounded,
              iconBg: AppColors.error,
              label: 'Delete Account',
              labelColor: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountDialog(context);
              },
            ),
          ],
        ),
      ),
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
                'This will permanently delete your account and all your data (ratings, watchlists, custom lists). This action cannot be undone.',
                style: TextStyle(color: colors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Type "Rate Me" to confirm:',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                cursorColor: AppColors.error,
                decoration: InputDecoration(
                  hintText: 'Rate Me',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.4),
                  ),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  color: ctrl.text == 'Rate Me'
                      ? AppColors.error
                      : colors.textSecondary.withValues(alpha: 0.3),
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
      ref.read(listsProvider.notifier).clearAll();
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

// ── Settings Card ─────────────────────────────────────────────────────────────

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
            color: colors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.6),
              width: 0.5,
            ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF30D158).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        size: 18,
                        color: Color(0xFF30D158),
                      ),
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
                Divider(height: 1, color: colors.border.withValues(alpha: 0.4)),
                _SettingRow(
                  icon: Icons.manage_accounts_rounded,
                  iconBg: AppColors.primary,
                  iconColor: Colors.black,
                  label: 'Account',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const _AccountSheet(),
                  ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Image.asset('assets/logo_and_images/app_bar.png', width: 36, height: 36),
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
}

// ── Editorial Stat ─────────────────────────────────────────────────────────────

class _EditorialStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final String? imagePath;

  const _EditorialStat({
    required this.value,
    required this.label,
    this.icon,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(imagePath!, width: 13, height: 13, color: AppColors.primary)
          else
            Icon(icon, color: AppColors.primary, size: 13),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Setting Row ───────────────────────────────────────────────────────────────

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
      final paths =
          await ref.read(tmdbServiceProvider).getBackdrops(movie.id, movie.mediaType);
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
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
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
                    _showingBackdrops
                        ? (_selectedMovie?.title ?? 'Pick a backdrop')
                        : 'Choose Cover',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
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
          _searchCtrl.text.isEmpty
              ? 'Search for a title to pick a cover'
              : 'No results found',
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
                    imageUrl: AppConstants.posterUrl(
                      movie.posterPath!,
                      size: AppConstants.posterW342,
                    ),
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _posterFallback(colors),
                  )
                : _posterFallback(colors),
          ),
          title: Text(
            movie.title,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${movie.mediaType == 'tv' ? 'TV Show' : 'Movie'}'
            '${movie.year.isNotEmpty ? ' · ${movie.year}' : ''}',
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
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
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
        final url =
            AppConstants.backdropUrl(_backdrops[i], size: AppConstants.backdropW780);
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
