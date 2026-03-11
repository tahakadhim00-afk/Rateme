import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Embeds a YouTube trailer that auto-plays as the detail page cover.
/// If the video is unavailable or has embedding disabled, shows [fallback].
class YoutubeTrailerPlayer extends StatefulWidget {
  final String videoKey;
  final Widget fallback;

  const YoutubeTrailerPlayer({
    super.key,
    required this.videoKey,
    required this.fallback,
  });

  @override
  State<YoutubeTrailerPlayer> createState() => _YoutubeTrailerPlayerState();
}

class _YoutubeTrailerPlayerState extends State<YoutubeTrailerPlayer> {
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubePlayerValue>? _sub;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoKey,
      autoPlay: true,
      params: const YoutubePlayerParams(
        mute: true,
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
    _sub = _controller.listen((value) {
      if (value.hasError && mounted && !_hasError) {
        setState(() => _hasError = true);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return widget.fallback;
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: 16 / 9,
      enableFullScreenOnVerticalDrag: false,
    );
  }
}
