import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

void showYouTubeCommentsPanel({
  required BuildContext context,
  required String videoId,
  required String accessToken,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return YouTubeCommentsBottomSheet(videoId: videoId, accessToken: accessToken);
    },
  );
}

class YouTubeCommentsBottomSheet extends StatefulWidget {
  final String videoId;
  final String accessToken;

  const YouTubeCommentsBottomSheet({super.key, required this.videoId, required this.accessToken});

  @override
  State<YouTubeCommentsBottomSheet> createState() => _YouTubeCommentsBottomSheetState();
}

class _YouTubeCommentsBottomSheetState extends State<YouTubeCommentsBottomSheet> {
  bool _isLoading = true;
  List<dynamic> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('https://www.googleapis.com/youtube/v3/commentThreads?part=snippet,replies&videoId=${widget.videoId}&maxResults=20'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      final data = jsonDecode(res.body);

      if (mounted) {
        setState(() {
          _comments = data['items'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch comments: $e')));
      }
    }
  }

  void _showReplyDialog(Map<String, dynamic> commentThread) {
    final snippet = commentThread['snippet']['topLevelComment']['snippet'];
    final author = snippet['authorDisplayName'];
    final text = snippet['textDisplay'];
    final commentId = commentThread['snippet']['topLevelComment']['id'];
    
    final TextEditingController replyController = TextEditingController();
    bool isGenerating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Reply to $author'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"$text"', style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isGenerating ? null : () async {
                        setDialogState(() => isGenerating = true);
                        try {
                          final callable = FirebaseFunctions.instance.httpsCallable('generateComment');
                          final result = await callable.call(<String, dynamic>{
                            'postContent': text,
                            'tone': 'helpful and encouraging',
                            'ctaLink': 'https://your-platform.com/course/123',
                            'promoCode': 'YOUTUBE20'
                          });
                          
                          setDialogState(() {
                            replyController.text = result.data as String;
                            isGenerating = false;
                          });
                        } catch (e) {
                          setDialogState(() => isGenerating = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('AI Generation failed: $e')),
                          );
                        }
                      },
                      icon: isGenerating 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                      label: Text(
                        isGenerating ? 'Generating...' : 'AutoFunnel Reply',
                        style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: replyController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Review and edit your reply...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (replyController.text.trim().isEmpty) return;
                    
                    try {
                      final response = await http.post(
                        Uri.parse('https://www.googleapis.com/youtube/v3/comments?part=snippet'),
                        headers: {
                          'Authorization': 'Bearer ${widget.accessToken}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          'snippet': {
                            'parentId': commentId,
                            'textOriginal': replyController.text.trim(),
                          }
                        }),
                      );
                      
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply posted!')));
                        _fetchComments(); // Refresh list
                      } else {
                        throw Exception("Failed with status ${response.statusCode}");
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post reply: $e')));
                    }
                  },
                  child: const Text('Send Reply'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manage Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty 
                ? const Center(child: Text('No comments found for this video.'))
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final commentThread = _comments[index];
                      final snippet = commentThread['snippet']['topLevelComment']['snippet'];
                      final author = snippet['authorDisplayName'];
                      final text = snippet['textDisplay'];
                      final authorProfileUrl = snippet['authorProfileImageUrl'];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage(authorProfileUrl)),
                          title: Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          trailing: OutlinedButton(
                            onPressed: () => _showReplyDialog(commentThread),
                            child: const Text('Reply'),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
