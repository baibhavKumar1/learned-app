import 'package:flutter/material.dart';
import '../../../../core/player/global_player_service.dart';
import '../../syllabus/video_page.dart';
import 'package:video_player/video_player.dart';

class BrutalistMiniPlayer extends StatelessWidget {
  const BrutalistMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GlobalPlayerService(),
      builder: (context, _) {
        final player = GlobalPlayerService();
        if (player.controller == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            // Expand back to video page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPage(
                  docId: player.currentDocId,
                  topicTitle: player.currentTitle,
                  chapterTitle: player.currentChapter,
                  videoUrl: player.currentUrl,
                  description: 'Continue watching...',
                  isFree: true,
                  price: 0,
                ),
              ),
            );
          },
          child: Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            'NOW PLAYING  •  ${player.currentTitle.toUpperCase()}  •  NOW PLAYING  •  ${player.currentTitle.toUpperCase()}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => player.togglePlayPause(),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => player.close(),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.redAccent,
                    child: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
