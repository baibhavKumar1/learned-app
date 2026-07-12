import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../models/clip_segment.dart';

/// Playlist player for Just-in-Time video stitching.
///
/// Receives a list of [ClipSegment] objects — each with a videoUrl, startSec,
/// and endSec pre-computed by Gemini at ingest time. Plays them sequentially,
/// seeking to [startSec] on load and auto-advancing when position reaches [endSec].
///
/// No AI is involved at playback time. All boundary decisions were made once,
/// server-side, when the educator's video was first processed.
class JitPlayerScreen extends StatefulWidget {
  final List<ClipSegment> clips;

  /// The index in [clips] to start playback from (defaults to 0).
  /// Allows tapping any result in the search list to start from that clip.
  final int initialIndex;

  const JitPlayerScreen({
    super.key,
    required this.clips,
    this.initialIndex = 0,
  });

  @override
  State<JitPlayerScreen> createState() => _JitPlayerScreenState();
}

class _JitPlayerScreenState extends State<JitPlayerScreen> {
  late int _currentIndex;
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  /// Polls position every 500 ms to detect when we have reached [endSec].
  /// Cancelled and re-created for each new clip.
  Timer? _endTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.clips.length - 1);
    _loadClip(_currentIndex);
  }

  @override
  void dispose() {
    _endTimer?.cancel();
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadClip(int index) async {
    if (index >= widget.clips.length) {
      // All clips have been played — close the screen
      if (mounted) Navigator.pop(context);
      return;
    }

    _endTimer?.cancel();

    // Dispose the previous controller before creating a new one
    final oldController = _controller;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _controller = null;
      });
    }
    await oldController?.pause();
    await oldController?.dispose();

    final clip = widget.clips[index];

    // Guard against malformed segment data
    if (clip.videoUrl.isEmpty || clip.endSec <= clip.startSec) {
      debugPrint(
        'JitPlayerScreen: skipping clip $index — invalid url or timestamps '
        '(startSec=${clip.startSec}, endSec=${clip.endSec})',
      );
      _loadClip(index + 1);
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(clip.videoUrl),
      );

      await controller.initialize();

      // Seek to the exact context boundary determined by Gemini at ingest time
      await controller.seekTo(
        Duration(milliseconds: (clip.startSec * 1000).round()),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _currentIndex = index;
        _isLoading = false;
      });

      await controller.play();

      // Poll position every 500 ms. When we reach endSec, advance to next clip.
      _endTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted || _controller == null) return;
        final positionSec =
            _controller!.value.position.inMilliseconds / 1000.0;
        if (positionSec >= clip.endSec) {
          _endTimer?.cancel();
          _loadClip(index + 1);
        }
      });
    } catch (e) {
      debugPrint('JitPlayerScreen: error loading clip $index — $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _skipToNext() {
    _endTimer?.cancel();
    _loadClip(_currentIndex + 1);
  }

  void _skipToPrevious() {
    if (_currentIndex > 0) {
      _endTimer?.cancel();
      _loadClip(_currentIndex - 1);
    }
  }

  String _formatDuration(double seconds) {
    final totalSec = seconds.round();
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clips[_currentIndex];
    final total = widget.clips.length;
    final clipDurationSec = clip.endSec - clip.startSec;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          'Clip ${_currentIndex + 1} of $total',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          if (!_isLoading && !_hasError && _controller != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  _formatDuration(clipDurationSec),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Video area ──────────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _isLoading
                ? const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : _hasError
                    ? ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white70,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Could not load this clip',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _skipToNext,
                                child: const Text(
                                  'Skip to next clip',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _togglePlayPause,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller!),
                            // Tap-to-pause overlay icon
                            AnimatedOpacity(
                              opacity:
                                  (_controller?.value.isPlaying ?? true)
                                      ? 0.0
                                      : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),

          // ── Clip progress bar ────────────────────────────────────────────
          if (_controller != null && !_isLoading)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (context, value, _) {
                final elapsed =
                    (value.position.inMilliseconds / 1000.0) - clip.startSec;
                final progress = clipDurationSec > 0
                    ? (elapsed / clipDurationSec).clamp(0.0, 1.0)
                    : 0.0;
                return LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            )
          else
            const LinearProgressIndicator(
              value: 0,
              minHeight: 3,
              backgroundColor: Colors.white24,
            ),

          // ── Clip info & controls ─────────────────────────────────────────
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic title
                    Text(
                      clip.topic,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clip.courseTitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      clip.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentIndex > 0 ? _skipToPrevious : null,
                          icon: const Icon(Icons.skip_previous_rounded),
                          iconSize: 36,
                          tooltip: 'Previous clip',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isLoading ? null : _togglePlayPause,
                          icon: Icon(
                            (_controller?.value.isPlaying ?? false)
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                          ),
                          iconSize: 60,
                          color: Theme.of(context).colorScheme.primary,
                          tooltip: 'Play / Pause',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed:
                              _currentIndex < total - 1 ? _skipToNext : null,
                          icon: const Icon(Icons.skip_next_rounded),
                          iconSize: 36,
                          tooltip: 'Next clip',
                        ),
                      ],
                    ),

                    // Playlist chips — tap any to jump directly to that clip
                    if (total > 1) ...[
                      const SizedBox(height: 24),
                      Text(
                        'All Clips',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(total, (i) {
                          final isActive = i == _currentIndex;
                          return GestureDetector(
                            onTap: () {
                              _endTimer?.cancel();
                              _loadClip(i);
                            },
                            child: Chip(
                              label: Text(
                                '${i + 1}. ${widget.clips[i].topic}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActive ? Colors.white : null,
                                ),
                              ),
                              backgroundColor: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
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
