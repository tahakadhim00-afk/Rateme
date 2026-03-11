
API Read Access Token
TMDB_READ_TOKEN_REMOVED
API Key
TMDB_API_KEY_REMOVED



# 📄 Product Requirements Document (PRD) – Rate Me App

## 1. Vision
Build the first Iraqi app dedicated to rating movies and TV shows, combining global data from TMDb with a localized experience. Users can log in, rate content, create personal lists (favorites, watched, watch later), and share their opinions with the community.

---

## 2. Goals
- Provide a simple and engaging platform for rating movies and TV shows.  
- Support both Arabic and English languages.  
- Deliver a localized experience (e.g., “Top 10 movies in Iraq this month”).  
- Implement secure authentication and storage using Supabase (PostgreSQL + Auth).  
- Integrate TMDb API for global movie and TV show data.  

---

## 3. Target Audience
- Iraqi and Arab youth passionate about cinema and TV shows.  
- Critics and enthusiasts who want to share reviews.  
- Users seeking both local and global recommendations.  

---

## 4. Core Features
### A. Authentication
- Email + password login.  
- OAuth login (Google, Facebook).  
- User profile management (username, avatar, language settings).  

### B. Lists
- **Favorites**: Save favorite movies.  
- **Watched**: Track watched content.  
- **Watch Later**: Save shows/movies for future viewing.  
- Ability to create custom lists (e.g., “Best Iraqi Films”).  

### C. Ratings & Reviews
- Rating system (stars 1–5 or localized icons).  
- Short text reviews.  
- Voting on “most helpful review.”  

### D. TMDb Integration
- Fetch movie/TV data (title, poster, description, genre).  
- Search by name or category.  
- Display trending/popular movies globally.  

### E. UI/UX
- Modern, minimal design using Flutter.  
- Bilingual support (Arabic/English).  
- Smooth experience with high-quality visuals.  

---

## 5. Technical Architecture
- **Frontend:** Flutter.  
- **Backend:** Supabase (PostgreSQL + Auth + Storage).  
- **Database Design:**  
  - `users`  
  - `movies` (from TMDb)  
  - `lists`  
  - `user_lists` (linking users, lists, and movies).  
- **API Integration:** TMDb API via `http` or `dio`.  
- **Caching:** Local SQLite for faster list rendering.  

---

## 6. Workflow
1. User signs in via Supabase.  
2. User browses movies fetched from TMDb.  
3. User adds a movie to a list (favorites, watched, watch later).  
4. Database stores only `user_id + movie_id + list_id`.  
5. When displaying lists, the app fetches movie details from TMDb.  

---

## 7. Milestones
- **Phase 1:** Authentication + movie browsing.  
- **Phase 2:** Lists creation and movie saving.  
- **Phase 3:** Ratings and reviews system.  
- **Phase 4:** UI/UX enhancements + Arabic language support.  
- **Phase 5:** Local beta launch.  

---

## 8. Success Metrics (KPIs)
- Number of registered users.  
- Number of movies added to lists.  
- Engagement rate (ratings/reviews).  
- User satisfaction via surveys.  