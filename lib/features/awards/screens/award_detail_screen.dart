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
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Collapsible header ───────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: colors.textPrimary, size: 20),
                onPressed: () => context.pop(),
              ),
              title: Text(
                name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _HeaderBanner(award: award, colors: colors),
              ),
            ),

            // ── Year filter bar ───────────────────────────────────────────
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
                  label: 'TOP MOVIES  ·  $_activeYear',
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
                child: _EmptyYear(year: _activeYear, colors: colors),
              ),

            // ── TV label ─────────────────────────────────────────────────
            if (_tvShows.isNotEmpty)
              SliverToBoxAdapter(
                child: _SectionLabel(
                  label: 'TOP TV SHOWS  ·  $_activeYear',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    final colors = AppThemeColors.of(context);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: years.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final year = years[i];
          final isSelected = year == selectedYear;
          return GestureDetector(
            onTap: () => onYearSelected(year),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        color: colors.border.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
              ),
              child: Text(
                year.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.black : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty state for a year with no results ────────────────────────────────────

class _EmptyYear extends StatelessWidget {
  final int year;
  final AppThemeColors colors;
  const _EmptyYear({required this.year, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.movie_filter_outlined,
              size: 40, color: colors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'No results for $year',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header banner ─────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  final Award? award;
  final AppThemeColors colors;
  const _HeaderBanner({required this.award, required this.colors});

  @override
  Widget build(BuildContext context) {
    final a = award;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 72, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (a != null && a.hasLogo)
              SizedBox(
                width: 64,
                height: 64,
                child: a.hasLocalAsset
                    ? Image.asset(
                        a.assetPath!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const _LogoPlaceholder(),
                      )
                    : Image.network(
                        a.logoUrl(size: 'h90')!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const _LogoPlaceholder(),
                      ),
              )
            else
              const _LogoPlaceholder(),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a?.name ?? '',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (a?.latestCeremonyDate != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 11, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          a!.latestCeremonyDate!,
                          style: TextStyle(
                              color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (a?.originCountry != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      a!.originCountry!,
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('🏆', style: TextStyle(fontSize: 28))),
      );
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();
  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: colors.card,
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
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
