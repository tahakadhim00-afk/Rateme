import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import 'rating_share_card.dart';

class ShareRatingSheet extends StatefulWidget {
  final String title;
  final String year;
  final String? posterUrl;

  /// Half-star scale 0.5–5.0.
  final double rating;

  /// Display name of the signed-in user.
  final String? username;

  const ShareRatingSheet({
    super.key,
    required this.title,
    required this.year,
    required this.posterUrl,
    required this.rating,
    this.username,
  });

  @override
  State<ShareRatingSheet> createState() => _ShareRatingSheetState();
}

class _ShareRatingSheetState extends State<ShareRatingSheet> {
  final _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture at 3× → 1080×1920 (Instagram Stories native resolution)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final safeTitle = widget.title.replaceAll(RegExp(r'[^\w]'), '_');
      final file = File(
          '${Directory.systemTemp.path}/rateme_${safeTitle}_rating.png');
      await file.writeAsBytes(bytes);

      final score = widget.rating == widget.rating.roundToDouble()
          ? '${widget.rating.toInt()}'
          : widget.rating.toStringAsFixed(1);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'I rated "${widget.title}" $score/5 on RateMe!',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            'Share Your Rating',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Card preview — scaled down to fit the sheet.
          // FittedBox scales it visually, but RepaintBoundary.toImage()
          // still captures the card at its intrinsic 360×640 size (1080×1920
          // at pixelRatio:3), so export quality is unaffected.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _cardKey,
                child: RatingShareCard(
                  title: widget.title,
                  year: widget.year,
                  posterUrl: widget.posterUrl,
                  rating: widget.rating,
                  username: widget.username,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _share,
              icon: _isSharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.ios_share_rounded,
                      color: Colors.black, size: 18),
              label: Text(
                _isSharing ? 'Preparing…' : 'Share to Instagram Story',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
