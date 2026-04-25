import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  static const _codeLength = 6;

  late final AnimationController _uiAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_codeLength, (_) => FocusNode());

  bool _loading = false;
  bool _hasError = false;

  // Resend cooldown
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _uiAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _uiAnim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _uiAnim, curve: Curves.easeOut));
    _uiAnim.forward();
    _startResendTimer();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes[0].requestFocus());
  }

  @override
  void dispose() {
    _uiAnim.dispose();
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _code =>
      _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < _codeLength) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      await ref.read(authNotifierProvider.notifier).verifyEmailOtp(
            email: widget.email,
            token: _code,
          );
      if (mounted) context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
      _shakeAndClear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _shakeAndClear() {
    HapticFeedback.mediumImpact();
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    await ref
        .read(authNotifierProvider.notifier)
        .resendConfirmation(widget.email);
    _startResendTimer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Code resent — check your inbox.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
    }
  }

  void _onDigitChanged(int index, String value) {
    setState(() => _hasError = false);

    if (value.length > 1) {
      // handle paste: distribute across boxes
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _codeLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final next = (digits.length < _codeLength) ? digits.length : _codeLength - 1;
      _focusNodes[next].requestFocus();
      if (digits.length >= _codeLength) _verify();
      return;
    }

    if (value.isNotEmpty) {
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verify();
      }
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name[0]}***@$domain';
    return '${name[0]}${name[1]}***@$domain';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isSignedInProvider, (_, isSignedIn) {
      if (isSignedIn && mounted) context.go('/home');
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0A0A), Color(0xFF111111), Color(0xFF0D0D0D)],
              ),
            ),
          ),

          // ── Subtle glow accent ───────────────────────────────────────────
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── UI ───────────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/signup'),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white60,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ── Icon ────────────────────────────────────────────────
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Headline ─────────────────────────────────────────────
                    const Text(
                      'Check your email',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'We sent a 6-digit code to\n',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45)),
                            ),
                            TextSpan(
                              text: _maskedEmail,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── OTP digit boxes ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          for (int i = 0; i < _codeLength; i++) ...[
                            Expanded(
                              child: _DigitBox(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                hasError: _hasError,
                                onChanged: (v) => _onDigitChanged(i, v),
                                onKeyEvent: (e) => _onKeyEvent(i, e),
                              ),
                            ),
                            if (i < _codeLength - 1) const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),

                    if (_hasError) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'Incorrect code. Please try again.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Verify button ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_loading || _code.length < _codeLength)
                              ? null
                              : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.3),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black54,
                                  ),
                                )
                              : const Text(
                                  'Verify Email',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Resend ────────────────────────────────────────────────
                    GestureDetector(
                      onTap: _resendSeconds == 0 ? _resend : null,
                      child: AnimatedOpacity(
                        opacity: _resendSeconds == 0 ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: "Didn't receive a code? ",
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              if (_resendSeconds > 0)
                                TextSpan(
                                  text: 'Resend in ${_resendSeconds}s',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                TextSpan(
                                  text: 'Resend',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
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

class _DigitBox extends StatefulWidget {
  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  @override
  State<_DigitBox> createState() => _DigitBoxState();
}

class _DigitBoxState extends State<_DigitBox> {
  // Dedicated FocusNode for KeyboardListener — properly disposed
  final _keyListenerNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _keyListenerNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    return SizedBox(
      height: 52,
      child: KeyboardListener(
        focusNode: _keyListenerNode,
        onKeyEvent: widget.onKeyEvent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: widget.hasError
                    ? AppColors.error.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.hasError
                      ? AppColors.error.withValues(alpha: 0.6)
                      : focused
                          ? AppColors.primary.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.15),
                  width: focused ? 1.8 : 1.2,
                ),
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                onChanged: widget.onChanged,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: widget.hasError ? AppColors.error : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
