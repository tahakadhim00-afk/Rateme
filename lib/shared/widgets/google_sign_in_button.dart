import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const GoogleSignInButton({
    super.key,
    required this.loading,
    required this.onTap,
  });

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
                        child: CustomPaint(painter: GoogleGPainter()),
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

/// Draws the official Google G logo using filled paths (24×24 coordinate space).
class GoogleGPainter extends CustomPainter {
  const GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    // Blue
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

    // Green
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

    // Yellow
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

    // Red
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
