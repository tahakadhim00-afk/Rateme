import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(watchedProvider);
    final watchLater = ref.watch(watchLaterProvider);
    final User? user = ref.watch(currentUserProvider);
    final isSignedIn = user != null;

    final movies = watched.where((e) => e.mediaType == 'movie').toList();
    final tvShows = watched.where((e) => e.mediaType == 'tv').toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeader(context, ref, user),
                const SizedBox(height: 24),
                _buildTopStats(context, watched.length, watchLater.length),
                const SizedBox(height: 12),
                _buildMediaTypeSplit(context, movies, tvShows),
                const SizedBox(height: 12),
                _buildGenreChart(context, watched),
                const SizedBox(height: 28),
                _buildSection(context, 'App', [
                  _SettingTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About RateMe',
                    onTap: () => _showAbout(context),
                  ),
                ]),
                const SizedBox(height: 16),
                if (!isSignedIn)
                  _buildSection(context, '', [
                    _SettingTile(
                      icon: Icons.login_rounded,
                      title: 'Sign In / Create Account',
                      iconColor: AppColors.primary,
                      titleColor: AppColors.primary,
                      onTap: () => context.go('/signin'),
                    ),
                  ])
                else
                  _buildSection(context, '', [
                    _SettingTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      iconColor: AppColors.error,
                      titleColor: AppColors.error,
                      onTap: () async {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .signOut();
                        ref.read(listsProvider.notifier).clearAll();
                        if (context.mounted) context.go('/signin');
                      },
                    ),
                  ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, User? user) {
    final isSignedIn = user != null;
    final displayName = isSignedIn
        ? ((user.userMetadata?['full_name'] as String?) ??
            user.email ??
            'Signed In')
        : 'Guest User';
    final avatarUrl =
        isSignedIn ? (user.userMetadata?['avatar_url'] as String?) : null;
    final coverUrl = ref.watch(coverProvider);
    final colors = AppThemeColors.of(context);

    return Column(
      children: [
        // ── Cover + avatar overlap ──────────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover image
            GestureDetector(
              onTap: () => _showCoverPicker(context, ref),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: colors.surface,
                ),
                child: coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _buildCoverPlaceholder(colors),
                      )
                    : _buildCoverPlaceholder(colors),
              ),
            ),
            // Dark gradient at bottom of cover so avatar stands out
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            // Camera edit button (top-right)
            Positioned(
              top: 48,
              right: 12,
              child: GestureDetector(
                onTap: () => _showCoverPicker(context, ref),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            // Avatar — centered, hanging below cover
            Positioned(
              bottom: -44,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(color: colors.background, width: 3),
                  ),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, e) => const Icon(
                              Icons.person_rounded,
                              color: Colors.black,
                              size: 44,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: Colors.black,
                            size: 44,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Space for avatar overhang
        const SizedBox(height: 56),
        Text(displayName, style: Theme.of(context).textTheme.headlineMedium),
        if (!isSignedIn) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go('/signin'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCoverPlaceholder(AppThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surface,
            colors.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: colors.textMuted,
        ),
      ),
    );
  }

  void _showCoverPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoverPickerSheet(parentRef: ref),
    );
  }

  Widget _buildTopStats(
    BuildContext context,
    int watchedCount,
    int watchLaterCount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppThemeColors.of(context).card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppThemeColors.of(context).border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              value: watchedCount.toString(),
              label: 'Watched',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            _Divider(),
            _StatItem(
              value: watchLaterCount.toString(),
              label: 'Watch Later',
              icon: Icons.bookmark_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTypeSplit(
    BuildContext context,
    List<UserListItem> movies,
    List<UserListItem> tvShows,
  ) {
    int minutesFor(List<UserListItem> items) => items
        .where((e) => e.runtime != null)
        .fold(0, (s, e) => s + e.runtime!);

    String fmtTime(int mins) {
      if (mins == 0) return '—';
      final d = mins ~/ (60 * 24);
      final h = (mins % (60 * 24)) ~/ 60;
      final m = mins % 60;
      if (d > 0) return '${d}d ${h}h';
      if (h > 0) return '${h}h ${m}m';
      return '${m}m';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _MediaTypeCard(
              icon: Icons.movie_rounded,
              label: 'Films',
              count: movies.length,
              timeLabel: fmtTime(minutesFor(movies)),
              color: const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MediaTypeCard(
              icon: Icons.tv_rounded,
              label: 'TV Shows',
              count: tvShows.length,
              timeLabel: fmtTime(minutesFor(tvShows)),
              color: const Color(0xFF00C9A7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChart(BuildContext context, List<UserListItem> watched) {
    final tally = <int, int>{};
    for (final item in watched) {
      for (final id in item.genreIds) {
        tally[id] = (tally[id] ?? 0) + 1;
      }
    }
    if (tally.isEmpty) return const SizedBox.shrink();

    final sorted = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sorted.take(8).toList();
    final maxCount = topEntries.first.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: AppThemeColors.of(context).card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppThemeColors.of(context).border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Genre Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topEntries.map((entry) {
              final name = kGenreNames[entry.key] ?? 'Other';
              final ratio = entry.value / maxCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GenreBar(
                  name: name,
                  count: entry.value,
                  ratio: ratio,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppThemeColors.of(context).textMuted,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            decoration: BoxDecoration(
              color: AppThemeColors.of(context).card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeColors.of(context).border, width: 0.5),
            ),
            child: Column(children: tiles),
          ),
        ],
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.movie_rounded,
                    color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Text('RateMe',
                  style: TextStyle(color: colors.textPrimary)),
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
      final results =
          await ref.read(tmdbServiceProvider).searchMulti(query.trim());
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
      final paths = await ref
          .read(tmdbServiceProvider)
          .getBackdrops(movie.id, movie.mediaType);
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
            child: Row(
              children: [
                if (_showingBackdrops)
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: colors.textPrimary),
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
          // Search bar (only on search view)
          if (!_showingBackdrops) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search movies or TV shows…',
                  hintStyle: TextStyle(color: colors.textMuted),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: colors.textMuted),
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
          ],
          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _showingBackdrops
                    ? _buildBackdropGrid()
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
                    imageUrl: AppConstants.posterUrl(movie.posterPath!,
                        size: AppConstants.posterW342),
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 40,
                      height: 60,
                      color: AppThemeColors.of(context).surfaceVariant,
                      child: Icon(Icons.movie_rounded,
                          size: 20,
                          color: AppThemeColors.of(context).textMuted),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppThemeColors.of(context).surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.movie_rounded,
                        size: 20,
                        color: AppThemeColors.of(context).textMuted),
                  ),
          ),
          title: Text(movie.title,
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${movie.mediaType == 'tv' ? 'TV Show' : 'Movie'}${movie.year.isNotEmpty ? ' · ${movie.year}' : ''}',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          trailing:
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          onTap: () => _loadBackdrops(movie),
        );
      },
    );
  }

  Widget _buildBackdropGrid() {
    if (_backdrops.isEmpty) {
      return Center(
        child: Text(
          'No backdrops available for this title',
          style: TextStyle(color: AppThemeColors.of(context).textMuted),
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
        final path = _backdrops[i];
        final url = AppConstants.backdropUrl(path,
            size: AppConstants.backdropW780);
        return GestureDetector(
          onTap: () => _pickBackdrop(path),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppThemeColors.of(context).surfaceVariant,
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppThemeColors.of(context).surfaceVariant,
                child: Icon(Icons.broken_image_outlined,
                    color: AppThemeColors.of(context).textMuted),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 48, color: AppThemeColors.of(context).border);
  }
}

class _MediaTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final String timeLabel;
  final Color color;

  const _MediaTypeCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.timeLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 12, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(
                timeLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenreBar extends StatelessWidget {
  final String name;
  final int count;
  final double ratio;

  const _GenreBar({
    required this.name,
    required this.count,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            name,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 8,
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
          width: 24,
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppThemeColors.of(context).textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: titleColor),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                color: AppThemeColors.of(context).textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
