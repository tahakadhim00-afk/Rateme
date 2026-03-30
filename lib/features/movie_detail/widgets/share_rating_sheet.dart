import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import 'rating_share_card.dart';

enum _SheetPage { card, backdrops, crop }

class ShareRatingSheet extends ConsumerStatefulWidget {
  final String title;
  final String year;
  final String? posterUrl;

  /// Half-star scale 0.5–5.0.
  final double rating;

  /// Display name of the signed-in user.
  final String? username;

  /// Optional review text to display on the card.
  final String? review;

  /// When provided, enables the "Edit Background" button which fetches
  /// backdrops for this media from TMDB. Leave null to hide the button
  /// (e.g. for episode ratings).
  final int? mediaId;
  final String mediaType;

  const ShareRatingSheet({
    super.key,
    required this.title,
    required this.year,
    required this.posterUrl,
    required this.rating,
    this.username,
    this.review,
    this.mediaId,
    this.mediaType = 'movie',
  });

  @override
  ConsumerState<ShareRatingSheet> createState() => _ShareRatingSheetState();
}

class _ShareRatingSheetState extends ConsumerState<ShareRatingSheet> {
  final _cardKey = GlobalKey();
  bool _isSharing = false;

  // ── Customisation ─────────────────────────────────────────────────────────
  _SheetPage _page = _SheetPage.card;
  String? _customBackdropUrl;
  Alignment _backdropAlignment = Alignment.center;

  // ── Backdrops page ────────────────────────────────────────────────────────
  List<String> _backdropPaths = [];
  bool _loadingBackdrops = false;

  // ── Crop page ─────────────────────────────────────────────────────────────
  String? _pendingBackdropUrl;
  Alignment _pendingAlignment = Alignment.center;
  double _dragStartX = 0;
  Alignment _alignmentAtDragStart = Alignment.center;

  String? get _effectiveBackdropUrl => _customBackdropUrl ?? widget.posterUrl;

  // ── Share ─────────────────────────────────────────────────────────────────

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

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

  // ── Backdrops ─────────────────────────────────────────────────────────────

  Future<void> _openBackdrops() async {
    setState(() {
      _page = _SheetPage.backdrops;
      _loadingBackdrops = _backdropPaths.isEmpty;
    });
    if (_backdropPaths.isNotEmpty) return; // already loaded
    try {
      final paths = await ref
          .read(tmdbServiceProvider)
          .getBackdrops(widget.mediaId!, widget.mediaType);
      if (mounted) setState(() => _backdropPaths = paths);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingBackdrops = false);
    }
  }

  void _openCrop(String backdropPath) {
    final url = AppConstants.backdropUrl(backdropPath,
        size: AppConstants.backdropW1280);
    setState(() {
      _pendingBackdropUrl = url;
      _pendingAlignment = Alignment.center;
      _page = _SheetPage.crop;
    });
  }

  void _applyCrop() {
    setState(() {
      _customBackdropUrl = _pendingBackdropUrl;
      _backdropAlignment = _pendingAlignment;
      _page = _SheetPage.card;
    });
  }

  // ── Crop pan ──────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    _dragStartX = d.localPosition.dx;
    _alignmentAtDragStart = _pendingAlignment;
  }

  void _onPanUpdate(DragUpdateDetails d, double displayWidth) {
    final dx = d.localPosition.dx - _dragStartX;
    final delta = (dx / displayWidth) * 2.0;
    final newX = (_alignmentAtDragStart.x - delta).clamp(-1.0, 1.0);
    setState(() => _pendingAlignment = Alignment(newX, _pendingAlignment.y));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (_page) {
          _SheetPage.card => _buildCardPage(colors),
          _SheetPage.backdrops => _buildBackdropsPage(context, colors),
          _SheetPage.crop => _buildCropPage(context, colors),
        },
      ),
    );
  }

  // ── Card page ─────────────────────────────────────────────────────────────

  Widget _buildCardPage(AppThemeColors colors) {
    return Column(
      key: const ValueKey('card'),
      mainAxisSize: MainAxisSize.min,
      children: [
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

        // Card preview
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: FittedBox(
            fit: BoxFit.contain,
            child: RepaintBoundary(
              key: _cardKey,
              child: RatingShareCard(
                title: widget.title,
                year: widget.year,
                posterUrl: _effectiveBackdropUrl,
                rating: widget.rating,
                username: widget.username,
                review: widget.review,
                backdropAlignment: _backdropAlignment,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Edit background — only shown when mediaId is available
        if (widget.mediaId != null)
          TextButton.icon(
            onPressed: _openBackdrops,
            icon: Icon(Icons.wallpaper_rounded,
                size: 16, color: colors.textSecondary),
            label: Text(
              _customBackdropUrl != null
                  ? 'Change Background'
                  : 'Edit Background',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),

        SizedBox(height: widget.mediaId != null ? 4 : 16),

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
    );
  }

  // ── Backdrops page ────────────────────────────────────────────────────────

  Widget _buildBackdropsPage(BuildContext context, AppThemeColors colors) {
    return SizedBox(
      key: const ValueKey('backdrops'),
      height: MediaQuery.of(context).size.height * 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: colors.textPrimary, size: 22),
                onPressed: () => setState(() => _page = _SheetPage.card),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 4),
              Text(
                'Choose Background',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_loadingBackdrops)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_backdropPaths.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No backdrops available',
                  style: TextStyle(color: colors.textMuted, fontSize: 14),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 16 / 9,
                ),
                itemCount: _backdropPaths.length,
                itemBuilder: (ctx, i) {
                  final path = _backdropPaths[i];
                  final thumbUrl = AppConstants.backdropUrl(path,
                      size: AppConstants.backdropW780);
                  return GestureDetector(
                    onTap: () => _openCrop(path),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: colors.surfaceVariant),
                        errorWidget: (_, _, _) => Container(
                          color: colors.surfaceVariant,
                          child: Icon(Icons.image_not_supported_rounded,
                              color: colors.textMuted),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Crop page ─────────────────────────────────────────────────────────────

  Widget _buildCropPage(BuildContext context, AppThemeColors colors) {
    const cardW = 360.0;
    const cardH = 640.0;
    final screenW = MediaQuery.of(context).size.width - 40;
    final maxDisplayH = MediaQuery.of(context).size.height * 0.54;
    final scale = (screenW / cardW).clamp(0.0, maxDisplayH / cardH);
    final displayW = cardW * scale;
    final displayH = cardH * scale;

    return SingleChildScrollView(
      key: const ValueKey('crop'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: colors.textPrimary, size: 22),
                onPressed: () =>
                    setState(() => _page = _SheetPage.backdrops),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 4),
              Text(
                'Adjust Crop',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Drag left or right to reposition',
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Interactive card preview
          Center(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: (d) => _onPanUpdate(d, displayW),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: displayW,
                  height: displayH,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: cardW,
                      height: cardH,
                      child: RatingShareCard(
                        title: widget.title,
                        year: widget.year,
                        posterUrl: _pendingBackdropUrl,
                        rating: widget.rating,
                        username: widget.username,
                        review: widget.review,
                        backdropAlignment: _pendingAlignment,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyCrop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
