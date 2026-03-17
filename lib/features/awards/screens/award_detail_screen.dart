import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/models/award.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/movie_card.dart';

class AwardDetailScreen extends ConsumerStatefulWidget {
  final int awardId;
  const AwardDetailScreen({super.key, required this.awardId});

  @override
  ConsumerState<AwardDetailScreen> createState() => _AwardDetailScreenState();
}

class _AwardDetailScreenState extends ConsumerState<AwardDetailScreen> {
  final _scrollController = ScrollController();
  final _yearScrollController = ScrollController();

  final List<Movie> _movies = [];
  int _moviePage = 1;
  bool _loadingMovies = false;
  bool _hasMoreMovies = true;

  final List<Movie> _tvShows = [];
  int _tvPage = 1;
  bool _loadingTv = false;
  bool _hasMoreTv = true;

  Award? _award;
  int? _selectedYear;

  static const int _startYear = 1990;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAward();
      _loadMovies();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _yearScrollController.dispose();
    super.dispose();
  }

  void _resolveAward() {
    final list = ref.read(awardsListProvider).valueOrNull ?? [];
    setState(() {
      _award = list.firstWhere(
        (a) => a.id == widget.awardId,
        orElse: () => Award(id: widget.awardId, name: 'Award'),
      );
    });
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 400) return;
    if (_hasMoreMovies) {
      _loadMovies();
    } else if (_hasMoreTv) {
      _loadTv();
    }
  }

  // Latest eligible year from award's ceremony date
  int get _defaultEligibleYear {
    final raw = _award?.latestCeremonyDate;
    if (raw == null) return DateTime.now().year - 1;
    try {
      final dt = DateTime.parse(raw);
      return dt.month <= 5 ? dt.year - 1 : dt.year;
    } catch (_) {
      return DateTime.now().year - 1;
    }
  }

  // The year currently shown (user selection or default)
  int get _activeYear => _selectedYear ?? _defaultEligibleYear;

  // All available years in descending order (newest first)
  List<int> get _yearRange {
    final end = _defaultEligibleYear;
    if (end < _startYear) return [end];
    return List.generate(end - _startYear + 1, (i) => end - i);
  }

  void _selectYear(int year) {
    if (year == _activeYear) return;
    setState(() {
      _selectedYear = year;
      _movies.clear();
      _moviePage = 1;
      _hasMoreMovies = true;
      _tvShows.clear();
      _tvPage = 1;
      _hasMoreTv = true;
    });
    _loadMovies();
    _scrollToSelectedYear(year);
  }

  void _scrollToSelectedYear(int year) {
    final index = _yearRange.indexOf(year);
    if (index == -1) return;
    const chipWidth = 64.0;
    const spacing = 8.0;
    final offset = index * (chipWidth + spacing);
    _yearScrollController.animateTo(
      offset.clamp(0.0, _yearScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadMovies() async {
    if (_loadingMovies || !_hasMoreMovies) return;
    setState(() => _loadingMovies = true);
    try {
      final results = await ref.read(tmdbServiceProvider).getAwardWinners(
            eligibleYear: _activeYear,
            mediaType: 'movie',
            page: _moviePage,
          );
      if (!mounted) return;
      setState(() {
        if (results.isEmpty) {
          _hasMoreMovies = false;
        } else {
          _movies.addAll(results);
          _moviePage++;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _hasMoreMovies = false);
    } finally {
      if (mounted) setState(() => _loadingMovies = false);
    }
  }

  Future<void> _loadTv() async {
    if (_loadingTv || !_hasMoreTv) return;
    setState(() => _loadingTv = true);
    try {
      final results = await ref.read(tmdbServiceProvider).getAwardWinners(
            eligibleYear: _activeYear,
            mediaType: 'tv',
            page: _tvPage,
          );
      if (!mounted) return;
      setState(() {
        if (results.isEmpty) {
          _hasMoreTv = false;
        } else {
          _tvShows.addAll(results);
          _tvPage++;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _hasMoreTv = false);
    } finally {
      if (mounted) setState(() => _loadingTv = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _movies.clear();
      _moviePage = 1;
      _hasMoreMovies = true;
      _tvShows.clear();
      _tvPage = 1;
      _hasMoreTv = true;
    });
    await _loadMovies();
  }

  void _onTap(Movie movie) {
    context.push(movie.mediaType == 'tv' ? '/tv/${movie.id}' : '/movie/${movie.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final award = _award;
    final name = award?.name ?? 'Awards';

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Collapsible hero header ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: colors.background,
              scrolledUnderElevation: 0,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                  onPressed: () => context.pop(),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _HeaderBanner(award: award),
              ),
            ),

            // ── Year filter bar ──────────────────────────────────────────
            if (_award != null)
              SliverToBoxAdapter(
                child: _YearFilterBar(
                  years: _yearRange,
                  selectedYear: _activeYear,
                  scrollController: _yearScrollController,
                  onYearSelected: _selectYear,
                ),
              ),

            // ── Movies label ─────────────────────────────────────────────
            if (_movies.isNotEmpty)
              SliverToBoxAdapter(
                child: _SectionLabel(
                  label: 'BEST FILMS',
                  year: _activeYear,
                  icon: Icons.movie_rounded,
                ),
              ),

            // ── Movies grid ──────────────────────────────────────────────
            if (_movies.isEmpty && _loadingMovies)
              const SliverToBoxAdapter(child: _SkeletonGrid())
            else if (_movies.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final w = (MediaQuery.of(ctx).size.width - 32 - 20) / 3;
                      return MovieCard(
                        movie: _movies[i],
                        width: w,
                        height: w / 0.67,
                        onTap: () => _onTap(_movies[i]),
                      );
                    },
                    childCount: _movies.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.67,
                  ),
                ),
              ),

            // ── No results placeholder ────────────────────────────────────
            if (!_loadingMovies && _movies.isEmpty && !_hasMoreMovies)
              SliverToBoxAdapter(
                child: _EmptyYear(year: _activeYear),
              ),

            // ── TV label ─────────────────────────────────────────────────
            if (_tvShows.isNotEmpty)
              SliverToBoxAdapter(
                child: _SectionLabel(
                  label: 'BEST SERIES',
                  year: _activeYear,
                  icon: Icons.tv_rounded,
                ),
              ),

            // ── TV grid ──────────────────────────────────────────────────
            if (_tvShows.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final w = (MediaQuery.of(ctx).size.width - 32 - 20) / 3;
                      return MovieCard(
                        movie: _tvShows[i],
                        width: w,
                        height: w / 0.67,
                        onTap: () => _onTap(_tvShows[i]),
                      );
                    },
                    childCount: _tvShows.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.67,
                  ),
                ),
              ),

            // ── Load more TV button ───────────────────────────────────────
            if (!_hasMoreMovies && _tvShows.isEmpty && !_loadingTv && _hasMoreTv)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: OutlinedButton.icon(
                    onPressed: _loadTv,
                    icon: const Icon(Icons.tv_rounded, size: 16),
                    label: const Text('Show TV Shows'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),

            // ── Loading spinner ───────────────────────────────────────────
            if (_loadingMovies || _loadingTv)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Header Banner ─────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  final Award? award;
  const _HeaderBanner({required this.award});

  @override
  Widget build(BuildContext context) {
    final a = award;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0B08),
      ),
      child: Stack(
        children: [
          // Background warm gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1508), Color(0xFF0D0B08)],
                ),
              ),
            ),
          ),

          // Radial glow behind logo
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content — centered column
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 52,
              20,
              20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                if (a != null && a.hasLogo)
                  _HeaderLogo(award: a)
                else
                  const _LogoPlaceholder(),

                const SizedBox(height: 14),

                // Award name
                Text(
                  a?.name ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Country + date row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (a?.originCountry != null) ...[
                      Text(
                        a!.originCountry!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (a.latestCeremonyDate != null)
                        Text(
                          '  ·  ',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                    if (a?.latestCeremonyDate != null)
                      Text(
                        _formatDate(a!.latestCeremonyDate!),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom fade to background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

class _HeaderLogo extends StatelessWidget {
  final Award award;
  const _HeaderLogo({required this.award});

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (award.hasLocalAsset) {
      img = Image.asset(
        award.assetPath!,
        width: 68,
        height: 68,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _LogoPlaceholder(),
      );
    } else {
      img = Image.network(
        award.logoUrl(size: 'h90')!,
        width: 68,
        height: 68,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _LogoPlaceholder(),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: img),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text('🏆', style: TextStyle(fontSize: 32)),
        ),
      );
}

// ── Year filter bar ────────────────────────────────────────────────────────────

class _YearFilterBar extends StatelessWidget {
  final List<int> years;
  final int selectedYear;
  final ScrollController scrollController;
  final ValueChanged<int> onYearSelected;

  const _YearFilterBar({
    required this.years,
    required this.selectedYear,
    required this.scrollController,
    required this.onYearSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Scrollable chips
          ListView.separated(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: years.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final year = years[i];
              final isSelected = year == selectedYear;
              return GestureDetector(
                onTap: () => onYearSelected(year),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFF1A1814),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppColors.border.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      letterSpacing: isSelected ? 0.3 : 0,
                    ),
                  ),
                ),
              );
            },
          ),
          // Left fade
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.background, Colors.transparent],
                ),
              ),
            ),
          ),
          // Right fade
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.background],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int year;
  final IconData icon;
  const _SectionLabel({
    required this.label,
    required this.year,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 14,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '·  $year',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty year state ───────────────────────────────────────────────────────────

class _EmptyYear extends StatelessWidget {
  final int year;
  const _EmptyYear({required this.year});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.06),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text('🎬', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No results for $year',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different year',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton Grid ──────────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1810),
      highlightColor: const Color(0xFF2A2418),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 10,
          childAspectRatio: 0.67,
        ),
        itemCount: 12,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1810),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
