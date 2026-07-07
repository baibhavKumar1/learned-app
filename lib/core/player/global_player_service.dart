import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GlobalPlayerService extends ChangeNotifier {
  static final GlobalPlayerService _instance = GlobalPlayerService._internal();
  factory GlobalPlayerService() => _instance;
  GlobalPlayerService._internal();

  VideoPlayerController? controller;
  bool isPlaying = false;
  
  String currentUrl = '';
  String currentTitle = '';
  String currentDocId = '';
  String currentChapter = '';

  Future<void> play({
    required String url, 
    required String title, 
    required String docId,
    required String chapter,
  }) async {
    if (currentUrl == url && controller != null) {
      // Already playing this video
      return;
    }
    
    // Dispose old
    await controller?.pause();
    await controller?.dispose();
    
    currentUrl = url;
    currentTitle = title;
    currentDocId = docId;
    currentChapter = chapter;
    
    controller = VideoPlayerController.networkUrl(Uri.parse(url));
    
    controller!.addListener(_onControllerUpdate);
    notifyListeners(); 
    
    await controller!.initialize();
    await controller!.play();
    notifyListeners();
  }
  
  void _onControllerUpdate() {
    if (controller != null) {
      if (isPlaying != controller!.value.isPlaying) {
        isPlaying = controller!.value.isPlaying;
        notifyListeners();
      }
    }
  }

  void togglePlayPause() {
    if (controller != null) {
      if (controller!.value.isPlaying) {
        controller!.pause();
      } else {
        controller!.play();
      }
    }
  }

  void close() {
    controller?.pause();
    controller?.dispose();
    controller = null;
    currentUrl = '';
    currentTitle = '';
    currentDocId = '';
    currentChapter = '';
    isPlaying = false;
    notifyListeners();
  }
}
