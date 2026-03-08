import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/lists/screens/lists_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/movie_detail/screens/movie_detail_screen.dart';
import '../../features/tv_detail/screens/tv_detail_screen.dart';
import '../../features/tv_detail/screens/tv_season_screen.dart';
import '../../features/actor/screens/actor_profile_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/home/screens/see_all_screen.dart';
import '../../core/services/supabase_service.dart';
import 'main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: supabaseService.isSignedIn ? '/home' : '/signin',
  redirect: (context, state) {
    // OAuth deep-link callback arrives as '/'
    if (state.uri.path == '/') {
      return supabaseService.isSignedIn ? '/home' : '/signin';
    }
    // Already signed in — skip the sign-in screen
    if (state.uri.path == '/signin' && supabaseService.isSignedIn) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/signin',
      builder: (ctx, state) => const SignInScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (ctx, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (ctx, state) => const NoTransitionPage(child: SearchScreen()),
        ),
        GoRoute(
          path: '/lists',
          pageBuilder: (ctx, state) => const NoTransitionPage(child: ListsScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (ctx, state) => const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/movie/:id',
      builder: (ctx, state) {
        final id = int.parse(state.pathParameters['id']!);
        return MovieDetailScreen(movieId: id);
      },
    ),
    GoRoute(
      path: '/tv/:id',
      builder: (ctx, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TvDetailScreen(tvId: id);
      },
    ),
    GoRoute(
      path: '/tv/:id/season/:season',
      builder: (ctx, state) {
        final id = int.parse(state.pathParameters['id']!);
        final season = int.parse(state.pathParameters['season']!);
        return TvSeasonScreen(tvId: id, seasonNumber: season);
      },
    ),
    GoRoute(
      path: '/actor/:id',
      builder: (ctx, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ActorProfileScreen(actorId: id);
      },
    ),
    GoRoute(
      path: '/see-all',
      builder: (ctx, state) {
        final category = state.uri.queryParameters['category']!;
        final title = state.uri.queryParameters['title']!;
        final mediaType = state.uri.queryParameters['mediaType'] ?? 'movie';
        return SeeAllScreen(category: category, title: title, mediaType: mediaType);
      },
    ),
  ],
);
