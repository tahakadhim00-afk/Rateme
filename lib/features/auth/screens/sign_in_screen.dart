import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/movie.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/google_sign_in_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _uiAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  Timer? _cycleTimer;
  int _currentIndex = 0;
  List<({Movie film, String posterPath})> _entries = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _uiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _uiAnim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _uiAnim, curve: Curves.easeOut));
    _uiAnim.forward();
  }

  @override
  void dispose() {
    _uiAnim.dispose();
    _cycleTimer?.cancel();
    super.dispose();
  }

  void _startCycling(List<({Movie film, String posterPath})> entries) {
    if (_cycleTimer != null) return;
    _entries = entries;
    _cycleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _currentIndex = (_currentIndex + 1) % _entries.length);
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign in failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _skip() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isSignedInProvider, (_, isSignedIn) {
      if (isSignedIn && mounted) context.go('/home');
    });

    final splashAsync = ref.watch(splashPostersProvider);
    splashAsync.whenData((entries) {
      if (entries.isNotEmpty && _cycleTimer == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startCycling(entries);
        });
      }
    });

    final current = _entries.isNotEmpty ? _entries[_currentIndex] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Full-screen poster image ────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: current != null
                ? CachedNetworkImage(
                    key: ValueKey('poster_${current.film.id}'),
                    imageUrl: AppConstants.posterUrl(
                      current.posterPath,
                      size: AppConstants.posterOriginal,
                    ),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, _) =>
                        const ColoredBox(color: Colors.black),
                    errorWidget: (_, _, _) =>
                        const ColoredBox(color: Colors.black),
                  )
                : const ColoredBox(
                    key: ValueKey('poster_empty'),
                    color: Colors.black,
                  ),
          ),

          // ── Layer 2: Gradient overlay — black from bottom ────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 0.65, 1.0],
                colors: [
                  Color(0x00000000),
                  Color(0x55000000),
                  Color(0xCC000000),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),

          // ── Layer 3: UI Content ──────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    const Spacer(),

                    // ── Film title + meta ──────────────────────────────────
                    if (current != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                current.film.title,
                                key: ValueKey('title_${current.film.id}'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded,
                                    color: AppColors.primary, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  current.film.ratingFormatted,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (current.film.year.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Container(
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: Colors.white24,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    current.film.year,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white38,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    // ── Divider ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── App identity ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo_and_images/app_bar.png',
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'RateMe',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Your personal cinema journal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Buttons ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          GoogleSignInButton(
                            loading: _loading,
                            onTap: _signInWithGoogle,
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: () => context.push('/signup'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.06),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Create an account',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          GestureDetector(
                            onTap: _skip,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'Skip for now',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'By signing in, you agree to our Terms & Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withValues(alpha: 0.18),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
