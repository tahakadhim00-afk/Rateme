import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/genre.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../shared/widgets/section_header.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final selectedGenre = ref.watch(selectedGenreProvider);
    final genreResults = selectedGenre != null
        ? ref.watch(discoverByGenreProvider(selectedGenre))
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text('Search',
                  style: Theme.of(context).textTheme.displayMedium),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(builder: (context) {
                final colors = AppThemeColors.of(context);
                return TextField(
                  controller: _controller,
                  style: TextStyle(color: colors.textPrimary),
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Movies, shows, genres...',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: colors.textMuted),
                    suffixIcon: _controller.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _controller.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                            child: Icon(Icons.close_rounded,
                                color: colors.textMuted),
                          )
                        : null,
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: query.trim().isEmpty
                  ? _BrowseView(
                      selectedGenre: selectedGenre,
                      genreResults: genreResults,
                    )
                  : results.when(
                      data: (movies) => movies.isEmpty
                          ? _EmptyResults(query: query)
                          : _SearchResults(movies: movies),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                      error: (e, _) => Center(
                        child: Text('Error: $e',
                            style: TextStyle(
                                color: AppThemeColors.of(context).textSecondary)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List movies;

  const _SearchResults({required this.movies});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (ctx, i) {
        final movie = movies[i];
        return MovieCard(
          movie: movie,
          width: double.infinity,
          onTap: () => ctx.push(
              movie.mediaType == 'tv' ? '/tv/${movie.id}' : '/movie/${movie.id}'),
        );
      },
    );
  }
}

class _BrowseView extends ConsumerWidget {
  final int? selectedGenre;
  final dynamic genreResults;

  const _BrowseView({this.selectedGenre, this.genreResults});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(genresProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Browse by Genre'),
          const SizedBox(height: 14),
          genres.when(
            data: (list) => _GenreChips(
              genres: list,
              selectedId: selectedGenre,
              onSelect: (id) =>
                  ref.read(selectedGenreProvider.notifier).state = id,
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, s) => _GenreChips(
              genres: kMovieGenres,
              selectedId: selectedGenre,
              onSelect: (id) =>
                  ref.read(selectedGenreProvider.notifier).state = id,
            ),
          ),
          if (selectedGenre != null && genreResults != null) ...[
            const SizedBox(height: 24),
            genreResults!.when(
              data: (movies) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: (movies as List).length,
                itemBuilder: (ctx, i) {
                  final movie = movies[i];
                  return MovieCard(
                    movie: movie,
                    width: double.infinity,
                    onTap: () => ctx.push('/movie/${movie.id}'),
                  );
                },
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child:
                    Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}

class _GenreChips extends StatelessWidget {
  final List<Genre> genres;
  final int? selectedId;
  final void Function(int?) onSelect;

  const _GenreChips({
    required this.genres,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: genres.map((g) {
          final selected = selectedId == g.id;
          return GestureDetector(
            onTap: () => onSelect(selected ? null : g.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : colors.border,
                  width: selected ? 1.5 : 0.5,
                ),
              ),
              child: Text(
                g.name,
                style: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;

  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              color: AppThemeColors.of(context).textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different title or keyword',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
