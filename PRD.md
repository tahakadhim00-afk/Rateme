# Product Requirements Document – Rate Me App

## 1. Vision
The first Iraqi app dedicated to rating movies and TV shows, combining global data from TMDb with a localized experience. Users sign in, rate content, build personal lists, and share their picks with the community.

---

## 2. Goals
- Simple, engaging platform for rating movies and TV shows.
- Support Arabic and English languages *(Arabic pending)*.
- Localized experience (e.g., "Top 10 in Iraq this month") *(planned)*.
- Secure authentication and storage via Supabase (PostgreSQL + Auth).
- TMDb API for global movie and TV show data.

---

## 3. Target Audience
- Iraqi and Arab youth passionate about cinema and TV.
- Critics and enthusiasts who want to share reviews.
- Users seeking local and global recommendations.

---

## 4. Features

### Authentication ✅
- Google OAuth via Supabase.
- Account deletion.
- Sign-in gate for all protected features (lists, ratings).
- Guest browsing (read-only, no auth required).

### Lists ✅
- **Watched** — track what you've seen.
- **Watch Later** — save for future viewing.
- **Custom Lists** — user-created lists (e.g., "Best Iraqi Films").
- Persisted via Supabase, tied to authenticated user.

### Ratings & Reviews ✅
- 0–10 rating scale per movie/TV show.
- Short text reviews stored in Supabase.
- TMDb community vote average displayed alongside personal rating.

### TMDb Integration ✅
- Trending, top-rated, and upcoming content.
- Movie and TV series detail pages (genres, cast, runtime, seasons/episodes).
- Actor profile pages.
- Search by title.
- Adult content blocking + vote-count validation.

### Share Cards ✅
- **Rating Card** — share your personal rating as an image.
- **Recommendation Card** — share a movie/show recommendation.
- Generated as image files and shared via native share sheet.

### Notifications ✅
- Daily local reminder (configurable time, stored in secure storage).
- *(Push notifications not yet implemented.)*

### UI/UX ✅
- Flutter, dark mode.
- Bottom navigation: Home, Search, Lists, Profile.
- Deep links: `/movie/:id`, `/tv/:id`.
- Shimmer loading, cached images, smooth animations.
- Carousel banners, blurred bottom nav, poster splash screen.

---

## 5. Technical Architecture
- **Frontend:** Flutter (Dart).
- **Backend:** Supabase (PostgreSQL + Auth + Storage).
- **API:** TMDb (REST, injected at build time via `--dart-define-from-file`).
- **Secrets:** `dart_defines/secrets.json` (gitignored) — copy from `secrets.example.json`.
- **Local storage:** `flutter_secure_storage` for settings/reminders.
- **Image caching:** `cached_network_image`.
- **Sharing:** `share_plus` + `screenshot` package.

### Database Schema
| Table | Purpose |
|---|---|
| `users` | Auth + profile data |
| `user_lists` | `user_id + movie_id + list_type` |
| `ratings` | `user_id + movie_id + score + review` |

---

## 6. Workflow
1. User opens app → guest browse or Google sign-in.
2. Browse movies/TV fetched from TMDb (trending, search, genre).
3. Sign-in required to rate, review, or save to lists.
4. Only `user_id + tmdb_id + list_type` stored; details fetched from TMDb on demand.
5. Share rating or recommendation card via native share sheet.

---

## 7. Milestones
| Phase | Status |
|---|---|
| Auth + movie browsing | ✅ Done |
| Lists (watched, watch later, custom) | ✅ Done |
| Ratings + text reviews | ✅ Done |
| Share cards | ✅ Done |
| Actor pages, TV seasons/episodes | ✅ Done |
| Arabic language support | 🔲 Planned |
| Local Iraq trending / community feed | 🔲 Planned |
| Push notifications | 🔲 Planned |
| Email/password sign-up | 🔲 Planned |

---

## 8. Success Metrics
- Registered users count.
- Movies/shows added to lists.
- Ratings and reviews submitted.
- Share card interactions.
- User satisfaction via surveys.

---

## 9. Running Locally
```bash
# 1. Copy secrets template
cp dart_defines/secrets.example.json dart_defines/secrets.json
# 2. Fill in TMDB_API_KEY, TMDB_READ_TOKEN, SUPABASE_URL, SUPABASE_ANON_KEY

# 3. Run
flutter run --dart-define-from-file=dart_defines/secrets.json
```
