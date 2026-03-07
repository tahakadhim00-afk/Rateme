import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

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
                      _GoogleSignInButton(
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

// ── Google Sign-In Button ───────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleSignInButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.black12,
          highlightColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                else ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(painter: _GoogleGPainter()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Draws the official Google G logo using filled paths (24×24 coordinate space).
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    // Blue — top-right + crossbar area
    canvas.drawPath(
      Path()
        ..moveTo(22.56, 12.25)
        ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
        ..lineTo(12, 10.0)
        ..lineTo(12, 14.26)
        ..lineTo(17.92, 14.26)
        ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
        ..lineTo(15.71, 20.34)
        ..lineTo(19.28, 20.34)
        ..cubicTo(21.36, 18.42, 22.56, 15.60, 22.56, 12.25)
        ..close(),
      Paint()..color = const Color(0xFF4285F4),
    );

    // Green — bottom
    canvas.drawPath(
      Path()
        ..moveTo(12, 23)
        ..cubicTo(14.97, 23, 17.46, 22.02, 19.28, 20.34)
        ..lineTo(15.71, 17.57)
        ..cubicTo(14.73, 18.23, 13.48, 18.63, 12, 18.63)
        ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
        ..lineTo(2.18, 14.10)
        ..lineTo(2.18, 16.94)
        ..cubicTo(3.99, 20.53, 7.70, 23, 12, 23)
        ..close(),
      Paint()..color = const Color(0xFF34A853),
    );

    // Yellow — left
    canvas.drawPath(
      Path()
        ..moveTo(5.84, 14.09)
        ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
        ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
        ..lineTo(5.84, 7.07)
        ..lineTo(2.18, 7.07)
        ..cubicTo(1.43, 8.55, 1, 10.22, 1, 12)
        ..cubicTo(1, 13.78, 1.43, 15.45, 2.18, 16.93)
        ..close(),
      Paint()..color = const Color(0xFFFBBC05),
    );

    // Red — top-left
    canvas.drawPath(
      Path()
        ..moveTo(12, 5.38)
        ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
        ..lineTo(19.36, 3.87)
        ..cubicTo(17.45, 2.09, 14.97, 1, 12, 1)
        ..cubicTo(7.70, 1, 3.99, 3.47, 2.18, 7.06)
        ..lineTo(5.84, 9.90)
        ..cubicTo(6.71, 7.30, 9.14, 5.38, 12, 5.38)
        ..close(),
      Paint()..color = const Color(0xFFEA4335),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
