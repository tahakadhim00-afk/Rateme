import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/google_sign_in_button.dart';

class _Slide {
  final String image;
  final String title;
  final String subtitle;
  const _Slide({required this.image, required this.title, required this.subtitle});
}

const _kSlides = [
  _Slide(
    image: 'assets/logo_and_images/rate_films_shows.png',
    title: 'Rate Films & Shows',
    subtitle: 'Share your thoughts on every title you watch',
  ),
  _Slide(
    image: 'assets/logo_and_images/creating_list.png',
    title: 'Build Your Lists',
    subtitle: 'Track watched titles and save what\'s next',
  ),
  _Slide(
    image: 'assets/logo_and_images/sync.png',
    title: 'Sync Everywhere',
    subtitle: 'Your lists stay with you across all devices',
  ),
];

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final PageController _pageController;
  Timer? _slideTimer;
  int _currentPage = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _pageController = PageController();
    _slideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final next = (_currentPage + 1) % _kSlides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    _slideTimer?.cancel();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      // signInWithOAuth just launches the browser — the session arrives later
      // via the deep-link callback. Navigation happens in the ref.listen below.
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
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
    // Navigate as soon as the OAuth callback lands and the session is real.
    ref.listen<bool>(isSignedInProvider, (_, isSignedIn) {
      if (isSignedIn && mounted) context.go('/home');
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                const SizedBox(height: 24),
                // ── Logo + title + subtitle ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo_and_images/app_bar.png',
                        width: 64,
                        height: 64,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'RateMe',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your personal cinema journal.\nRate, save & discover.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppThemeColors.of(context).textSecondary,
                              height: 1.55,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // ── Illustration carousel ──────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _kSlides.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) {
                      final slide = _kSlides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Image.asset(
                                slide.image,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppThemeColors.of(context)
                                        .textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Dot indicators
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _kSlides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.primary
                            : AppThemeColors.of(context).border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // ── Buttons ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      GoogleSignInButton(
                        loading: _loading,
                        onTap: _signInWithGoogle,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              AppThemeColors.of(context).textMuted,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                AppThemeColors.of(context).textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'By signing in, you agree to our Terms & Privacy Policy.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppThemeColors.of(context).textMuted,
                                  fontSize: 11,
                                ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

