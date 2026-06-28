import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class VideoPage extends StatefulWidget {
  final String docId;
  final String topicTitle;
  final String chapterTitle;
  final String videoUrl;
  final String? pdfUrl;
  final String? pdfFileName;
  final String description;
  final bool isFree;
  final dynamic price;

  const VideoPage({
    super.key,
    required this.docId,
    required this.topicTitle,
    required this.chapterTitle,
    required this.videoUrl,
    this.pdfUrl,
    this.pdfFileName,
    required this.description,
    required this.isFree,
    required this.price,
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  String? _userReaction;
  final _commentController = TextEditingController();
  final GlobalKey<_CustomVideoPlayerState> _videoPlayerKey = GlobalKey();
  late Stream<QuerySnapshot> _commentsStream;

  @override
  void initState() {
    super.initState();
    _incrementViews();
    _fetchUserReaction();
    _initializeCommentsStream();
  }

  void _incrementViews() {
    if (widget.docId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('course_materials')
          .doc(widget.docId)
          .update({'views': FieldValue.increment(1)}).catchError((e) {
        debugPrint('Error incrementing views: $e');
      });
    }
  }

  void _initializeCommentsStream() {
    if (widget.docId.isNotEmpty) {
      _commentsStream = FirebaseFirestore.instance
          .collection('course_materials')
          .doc(widget.docId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Future<void> _fetchUserReaction() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.docId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('course_materials')
          .doc(widget.docId)
          .collection('reactions')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userReaction = doc.data()?['type'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user reaction: $e');
    }
  }

  Future<void> _react(String reactionType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.docId.isEmpty) return;

    final docRef = FirebaseFirestore.instance.collection('course_materials').doc(widget.docId);
    final userReactRef = docRef.collection('reactions').doc(uid);

    try {
      if (_userReaction != null) {
        if (_userReaction == reactionType) {
          // Toggle off
          await userReactRef.delete();
          if (_userReaction == 'like') {
            await docRef.update({'likesCount': FieldValue.increment(-1)});
          } else if (_userReaction == 'dislike') {
            await docRef.update({'dislikesCount': FieldValue.increment(-1)});
          }
          setState(() {
            _userReaction = null;
          });
          return;
        } else {
          // Undo previous
          if (_userReaction == 'like') {
            await docRef.update({'likesCount': FieldValue.increment(-1)});
          } else if (_userReaction == 'dislike') {
            await docRef.update({'dislikesCount': FieldValue.increment(-1)});
          }
        }
      }

      await userReactRef.set({'type': reactionType});
      if (reactionType == 'like') {
        await docRef.update({'likesCount': FieldValue.increment(1)});
      } else if (reactionType == 'dislike') {
        await docRef.update({'dislikesCount': FieldValue.increment(1)});
      }

      setState(() {
        _userReaction = reactionType;
      });
    } catch (e) {
      debugPrint('Error reacting: $e');
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.docId.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('course_materials')
          .doc(widget.docId)
          .collection('comments')
          .add({
        'studentId': user.uid,
        'studentName': user.displayName ?? 'Student',
        'commentText': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('course_materials')
          .doc(widget.docId)
          .update({'commentsCount': FieldValue.increment(1)});

      _commentController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint('Error posting comment: $e');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: CustomVideoPlayer(
              key: _videoPlayerKey,
              videoUrl: widget.videoUrl,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomVideoPlayer(
              key: _videoPlayerKey,
              videoUrl: widget.videoUrl,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.topicTitle,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.chapterTitle,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildEmojiPickerButton(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'About This Topic',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) ...[
                    const Text(
                      'Study Material',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        ),
                        title: Text(widget.pdfFileName ?? 'Lecture Note PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Formula sheet & solved examples'),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () async {
                            final uri = Uri.parse(widget.pdfUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Comments section
                  const Text(
                    'Comments & Discussion',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildCommentsList(),
                  const SizedBox(height: 16),
                  _buildCommentInput(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPickerButton() {
    final emoji = _userReaction == 'like'
        ? '👍'
        : _userReaction == 'dislike'
            ? '👎'
            : '😊';

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
      tooltip: 'React to this video',
      onSelected: (String reaction) {
        _react(reaction);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'like',
          child: Row(
            children: [
              Text('👍', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Thumbs Up'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'dislike',
          child: Row(
            children: [
              Text('👎', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Thumbs Down'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    if (widget.docId.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: _commentsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading comments');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No comments yet. Start the discussion!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final time = (data['createdAt'] as Timestamp?)?.toDate();
            final formattedTime = time != null
                ? '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                : 'Just now';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, size: 16, color: Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              data['studentName'] ?? 'Anonymous',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              formattedTime,
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['commentText'] ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a public comment...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
          onPressed: _postComment,
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// Isolated Standalone Video Player Widget (Option 3)
// ----------------------------------------------------
class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isError = false;

  bool _showControls = true;
  double _currentPositionMs = 0;
  double _totalDurationMs = 0;
  double _playbackSpeed = 1.0;
  Timer? _controlsTimer;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    if (widget.videoUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      _controller!.initialize().then((_) {
        if (mounted) {
          _controller!.addListener(_videoListener);
          setState(() {
            _isInitialized = true;
            _totalDurationMs = _controller!.value.duration.inMilliseconds.toDouble();
          });
          _controller!.play();
          _startPositionTimer();
          _startControlsTimer();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isError = true;
          });
        }
        debugPrint('Video Player Init Error: $error');
      });
    }
  }

  void _videoListener() {
    if (_controller != null && _controller!.value.isInitialized) {
      final pos = _controller!.value.position.inMilliseconds.toDouble();
      final dur = _controller!.value.duration.inMilliseconds.toDouble();
      if (mounted) {
        setState(() {
          _currentPositionMs = pos;
          if (dur > 0) {
            _totalDurationMs = dur;
          }
        });
      }
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_controller != null && _controller!.value.isInitialized) {
        final pos = _controller!.value.position.inMilliseconds.toDouble();
        final dur = _controller!.value.duration.inMilliseconds.toDouble();
        if (mounted) {
          setState(() {
            _currentPositionMs = pos;
            if (dur > 0) {
              _totalDurationMs = dur;
            }
          });
        }
      }
    });
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controlsTimer?.cancel();
    _positionTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _toggleOrientation(bool isLandscape) {
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (!_isInitialized || _controller == null) {
      return Container(
        height: isLandscape ? MediaQuery.of(context).size.height : 220,
        color: Colors.black,
        child: _isError
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text('Failed to load video.', style: TextStyle(color: Colors.white)),
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
      );
    }

    return Container(
      height: isLandscape ? MediaQuery.of(context).size.height : 220,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered AspectRatio video player (retains native bounds, handles vertical/horizontal orientation)
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          
          // Toggle control overlay on tap (covers full screen container width)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                  if (_showControls) {
                    _startControlsTimer();
                  }
                });
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Controls overlay panel (stretches to full width of the container, avoiding aspect-ratio constraint squeeze)
          if (_showControls)
            Positioned.fill(
              child: _buildControlsOverlay(isLandscape),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay(bool isLandscape) {
    final isPlaying = _controller?.value.isPlaying ?? false;
    final isMuted = _controller?.value.volume == 0.0;

    return Stack(
      children: [
        // Dark gradient overlay at the bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
        ),

        // Controls container (stretches to full width of screen)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edge-to-edge Progress Slider (SeekBar) stretching to full 90%
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2.0,
                  activeTrackColor: Colors.red,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.red,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Container(
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.zero,
                  child: Slider(
                    value: _currentPositionMs.clamp(0.0, _totalDurationMs),
                    min: 0.0,
                    max: _totalDurationMs > 0.0 ? _totalDurationMs : 1.0,
                    onChanged: (value) {
                      setState(() {
                        _currentPositionMs = value;
                      });
                      _controller?.seekTo(Duration(milliseconds: value.toInt()));
                    },
                    onChangeStart: (_) {
                      _controlsTimer?.cancel();
                    },
                    onChangeEnd: (_) {
                      _startControlsTimer();
                    },
                  ),
                ),
              ),

              // Control Buttons and Labels Row
              Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Controls: Play/Pause, Volume, Time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isPlaying) {
                                _controller?.pause();
                                _positionTimer?.cancel();
                              } else {
                                _controller?.play();
                                _startPositionTimer();
                              }
                              _startControlsTimer();
                            });
                          },
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller?.setVolume(isMuted ? 1.0 : 0.0);
                              _startControlsTimer();
                            });
                          },
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatDuration(Duration(milliseconds: _currentPositionMs.toInt()))} / ${_formatDuration(Duration(milliseconds: _totalDurationMs.toInt()))}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    // Right Controls: Settings (Speed Picker) and Fullscreen Toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Playback Speed Selector (Gear Icon ⚙️)
                        PopupMenuButton<double>(
                          initialValue: _playbackSpeed,
                          tooltip: 'Playback speed',
                          onSelected: (double speed) {
                            _controller?.setPlaybackSpeed(speed);
                            setState(() {
                              _playbackSpeed = speed;
                            });
                            _startControlsTimer();
                          },
                          itemBuilder: (context) => [0.5, 1.0, 1.5, 2.0]
                              .map((speed) => PopupMenuItem<double>(
                                    value: speed,
                                    child: Text('${speed}x'),
                                  ))
                              .toList(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                            child: Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            isLandscape ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _toggleOrientation(isLandscape),
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
