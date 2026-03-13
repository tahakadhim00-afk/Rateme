import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/person_preference.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // person_id → PersonResult for all selected people
  final Map<int, PersonResult> _selected = {};

  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSaving = false;

  static const _minRequired = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(peopleSearchQueryProvider.notifier).state = v.trim();
    });
  }

  void _toggle(PersonResult person) {
    setState(() {
      if (_selected.containsKey(person.id)) {
        _selected.remove(person.id);
      } else {
        _selected[person.id] = person;
      }
    });
  }

  Future<void> _saveAndContinue() async {
    if (_selected.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    final prefs = _selected.values.map((p) {
      final type = p.isDirector ? 'director' : 'actor';
      return PersonPreference(
        personId: p.id,
        personName: p.name,
        personType: type,
        profilePath: p.profilePath,
        addedAt: DateTime.now(),
      );
    }).toList();

    await supabaseService.savePreferences(prefs);
    ref.invalidate(userPreferencesProvider);

    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(peopleSearchQueryProvider);
    final isSearching = query.isNotEmpty;
    final selectedCount = _selected.length;
    final canContinue = selectedCount >= _minRequired;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tell us what\nyou love',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pick your favourite actors & directors\nto personalise your home feed.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                            height: 1.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'Poppins', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search actors & directors…',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.45), size: 20),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.45),
                              size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(peopleSearchQueryProvider.notifier)
                                .state = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Tabs (hidden during search) ────────────────────────────────
            if (!isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _PillTabBar(controller: _tabController),
              ),

            if (!isSearching) const SizedBox(height: 12),

            // ── Grid ──────────────────────────────────────────────────────
            Expanded(
              child: isSearching
                  ? _SearchGrid(selected: _selected, onTap: _toggle)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _PopularGrid(
                          department: 'Acting',
                          selected: _selected,
                          onTap: _toggle,
                        ),
                        _PopularGrid(
                          department: 'Directing',
                          selected: _selected,
                          onTap: _toggle,
                        ),
                      ],
                    ),
            ),

            // ── Bottom bar ────────────────────────────────────────────────
            _BottomBar(
              selectedCount: selectedCount,
              minRequired: _minRequired,
              canContinue: canContinue,
              isSaving: _isSaving,
              onContinue: _saveAndContinue,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pill tab bar ──────────────────────────────────────────────────────────────

class _PillTabBar extends StatelessWidget {
  final TabController controller;
  const _PillTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Actors'),
          Tab(text: 'Directors'),
        ],
      ),
    );
  }
}

// ── Popular people grid (paginated) ──────────────────────────────────────────

class _PopularGrid extends ConsumerStatefulWidget {
  final String department; // 'Acting' | 'Directing'
  final Map<int, PersonResult> selected;
  final ValueChanged<PersonResult> onTap;

  const _PopularGrid({
    required this.department,
    required this.selected,
    required this.onTap,
  });

  @override
  ConsumerState<_PopularGrid> createState() => _PopularGridState();
}

class _PopularGridState extends ConsumerState<_PopularGrid>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  /// Raw TMDB /person/popular page counter — advances independently of how
  /// many filtered results we've accumulated (directors are sparse, so we
  /// may burn several pages per visible batch).
  int _rawPage = 1;

  final List<PersonResult> _people = [];
  bool _loading = false;
  bool _hasMore = true;

  /// Min number of matching people to collect before surfacing a batch.
  static const _batchSize = 9;

  /// Hard stop — /person/popular has ~500 pages; beyond that it repeats.
  static const _maxPage = 500;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadBatch();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _loadBatch();
    }
  }

  /// Keeps fetching TMDB pages until we've collected [_batchSize] people
  /// of [widget.department], or we've reached [_maxPage].
  Future<void> _loadBatch() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    try {
      final service = ref.read(tmdbServiceProvider);
      final batch = <PersonResult>[];

      while (batch.length < _batchSize && _rawPage <= _maxPage) {
        final page = await service.getPopularPeople(page: _rawPage);
        _rawPage++;
        batch.addAll(
          page.where((p) => p.knownForDepartment == widget.department),
        );
        if (page.isEmpty) break; // TMDB returned nothing — truly exhausted
      }

      setState(() {
        _people.addAll(batch);
        _hasMore = _rawPage <= _maxPage && batch.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_people.isEmpty && _loading) {
      return _buildShimmer();
    }
    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: _people.length + (_loading ? _batchSize : 0),
      itemBuilder: (ctx, i) {
        if (i >= _people.length) return const _ShimmerPersonCard();
        return _PersonCard(
          person: _people[i],
          isSelected: widget.selected.containsKey(_people[i].id),
          onTap: () => widget.onTap(_people[i]),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: 12,
      itemBuilder: (_, i) => const _ShimmerPersonCard(),
    );
  }
}

// ── Search results grid ────────────────────────────────────────────────────────

class _SearchGrid extends ConsumerWidget {
  final Map<int, PersonResult> selected;
  final ValueChanged<PersonResult> onTap;

  const _SearchGrid({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(peopleSearchResultsProvider);
    return results.when(
      loading: () => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: 6,
        itemBuilder: (_, i) => const _ShimmerPersonCard(),
      ),
      error: (e, s) => const SizedBox.shrink(),
      data: (people) {
        if (people.isEmpty) {
          return Center(
            child: Text(
              'No results found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: people.length,
          itemBuilder: (ctx, i) => _PersonCard(
            person: people[i],
            isSelected: selected.containsKey(people[i].id),
            onTap: () => onTap(people[i]),
          ),
        );
      },
    );
  }
}

// ── Person card ────────────────────────────────────────────────────────────────

class _PersonCard extends StatelessWidget {
  final PersonResult person;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonCard({
    required this.person,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
            child: Stack(
              children: [
                // Photo
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: AppConstants.posterUrl(
                      person.profilePath!,
                      size: AppConstants.posterW342,
                    ),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      width: 88,
                      height: 88,
                      color: const Color(0xFF1C1C1E),
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      width: 88,
                      height: 88,
                      color: const Color(0xFF1C1C1E),
                      child: Icon(Icons.person_rounded,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 36),
                    ),
                  ),
                ),
                // Selection overlay
                if (isSelected)
                  Positioned.fill(
                    child: ClipOval(
                      child: Container(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        child: const Center(
                          child: Icon(Icons.check_rounded,
                              color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            person.name,
            style: TextStyle(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.85),
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Poppins',
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Shimmer card ───────────────────────────────────────────────────────────────

class _ShimmerPersonCard extends StatelessWidget {
  const _ShimmerPersonCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}

// ── Bottom bar ─────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int selectedCount;
  final int minRequired;
  final bool canContinue;
  final bool isSaving;
  final VoidCallback onContinue;

  const _BottomBar({
    required this.selectedCount,
    required this.minRequired,
    required this.canContinue,
    required this.isSaving,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Selection count chip
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selectedCount == 0
                ? Text(
                    'Choose at least $minRequired',
                    key: const ValueKey('hint'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  )
                : Container(
                    key: ValueKey(selectedCount),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: canContinue
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: canContinue
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$selectedCount selected',
                      style: TextStyle(
                        color: canContinue
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
          ),
          const Spacer(),
          // Continue button
          AnimatedOpacity(
            opacity: canContinue ? 1.0 : 0.35,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: canContinue ? onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.primary,
                  disabledForegroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
