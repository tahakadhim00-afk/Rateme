# RateMe

Flutter movie & TV show tracker. Users can browse, rate, and save films to Watched / Watch Later lists, synced via Supabase.

---

## Stack

| Layer | Tech |
|---|---|
| Framework | Flutter (Dart 3.10+) |
| State | flutter_riverpod 2.6 (StateNotifier + FutureProvider) |
| Navigation | go_router 14 |
| Backend | Supabase (auth + `user_lists` table) |
| Auth | Google OAuth via Supabase |
| Movie data | TMDB API v3 (Bearer token) |
| HTTP | Dio 5 |
| Images | cached_network_image |

---

## Project structure

```
lib/
  core/
    constants/    # AppConstants — TMDB base URLs, image helpers
    models/       # Movie, MovieDetail, Cast, ActorDetail, UserListItem, Genre
    providers/    # tmdb_providers, lists_provider, auth_provider
    services/     # TmdbService (Dio), SupabaseService
    theme/        # AppTheme, AppColors, AppThemeColors
  features/
    auth/         # SignInScreen (Google OAuth)
    home/         # HomeScreen, MovieRow widget, FeaturedBanner
    search/       # SearchScreen
    lists/        # ListsScreen (Watched / Watch Later tabs)
    movie_detail/ # MovieDetailScreen
    actor/        # ActorProfileScreen
  shared/
    navigation/   # GoRouter (app_router), MainScaffold (bottom nav)
    widgets/      # MovieCard, MovieListTile, RatingBadge, SectionHeader
```

---

## Key decisions

- **Watched / Watch Later are mutually exclusive** — toggling one removes the other (`toggleWatched` / `toggleWatchLater` in `ListsNotifier`).
- **Favorites list exists in the DB schema** but is hidden from the UI (removed per product decision).
- **Guest mode** is supported. Items added before sign-in are uploaded to Supabase on first sign-in (`loadFromSupabase` merges local state first).
- **MovieCard** displays title, rating, year in a frosted-glass blurred overlay inside the poster (no text below).
- **Cast** is fetched via `append_to_response=credits` on the TMDB movie detail endpoint and shown as a horizontal scroll on the detail screen. Each actor links to `ActorProfileScreen` (`/actor/:id`).
- **Actor profile** uses `/person/:id?append_to_response=movie_credits`.

---

## Supabase

Table: `user_lists`
Primary key: `id` (uuid)
Unique constraint: `(user_id, media_id, list_type)`
RLS: users can only read/write their own rows.
`list_type` allowed values: `'watched'`, `'watchLater'`, `'favorites'`

---

## Routes

| Path | Screen |
|---|---|
| `/signin` | SignInScreen |
| `/home` | HomeScreen |
| `/search` | SearchScreen |
| `/lists` | ListsScreen |
| `/profile` | ProfileScreen |
| `/movie/:id` | MovieDetailScreen |
| `/actor/:id` | ActorProfileScreen |
