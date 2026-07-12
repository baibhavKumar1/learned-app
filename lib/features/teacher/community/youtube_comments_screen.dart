import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class YouTubeCommentsScreen extends StatefulWidget {
  const YouTubeCommentsScreen({super.key});

  @override
  State<YouTubeCommentsScreen> createState() => _YouTubeCommentsScreenState();
}

class _YouTubeCommentsScreenState extends State<YouTubeCommentsScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube.force-ssl',
    ],
  );

  GoogleSignInAccount? _currentUser;
  bool _isLoading = false;
  List<dynamic> _comments = [];
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        final auth = await _currentUser!.authentication;
        _accessToken = auth.accessToken;
        _fetchComments();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      debugPrint("Error signing in: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $error')),
      );
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Future<void> _fetchComments() async {
    if (_accessToken == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Step 1: Get the user's channel ID
      final channelRes = await http.get(
        Uri.parse('https://www.googleapis.com/youtube/v3/channels?part=contentDetails&mine=true'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      final channelData = jsonDecode(channelRes.body);
      
      if (channelData['items'] == null || channelData['items'].isEmpty) {
        throw Exception("No YouTube channel found.");
      }
      
      final uploadsPlaylistId = channelData['items'][0]['contentDetails']['relatedPlaylists']['uploads'];

      // Step 2: Get the most recent video
      final playlistRes = await http.get(
        Uri.parse('https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$uploadsPlaylistId&maxResults=1'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      final playlistData = jsonDecode(playlistRes.body);
      
      if (playlistData['items'] == null || playlistData['items'].isEmpty) {
        setState(() {
          _comments = [];
          _isLoading = false;
        });
        return;
      }

      final videoId = playlistData['items'][0]['snippet']['resourceId']['videoId'];

      // Step 3: Get comments for that video
      final commentsRes = await http.get(
        Uri.parse('https://www.googleapis.com/youtube/v3/commentThreads?part=snippet,replies&videoId=$videoId&maxResults=20'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      final commentsData = jsonDecode(commentsRes.body);

      setState(() {
        _comments = commentsData['items'] ?? [];
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching comments: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch comments: $e')),
      );
    }
  }

  void _showCommentDetails(Map<String, dynamic> commentThread) {
    final snippet = commentThread['snippet']['topLevelComment']['snippet'];
    final author = snippet['authorDisplayName'];
    final text = snippet['textDisplay'];
    final commentId = commentThread['snippet']['topLevelComment']['id'];
    
    final TextEditingController replyController = TextEditingController();
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reply to Comment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text('Posted by $author', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 24),
                  
                  // AI Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isGenerating ? null : () async {
                        setModalState(() => isGenerating = true);
                        try {
                          final callable = FirebaseFunctions.instance.httpsCallable('generateComment');
                          final result = await callable.call(<String, dynamic>{
                            'postContent': text,
                            'tone': 'helpful and informative',
                          });
                          
                          setModalState(() {
                            replyController.text = result.data as String;
                            isGenerating = false;
                          });
                        } catch (e) {
                          setModalState(() => isGenerating = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('AI Generation failed: $e')),
                          );
                        }
                      },
                      icon: isGenerating 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                      label: Text(
                        isGenerating ? 'Generating...' : 'Generate AI Reply',
                        style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurple),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (replyController.text.trim().isEmpty) return;
                        
                        // Post reply to YouTube API
                        try {
                          final response = await http.post(
                            Uri.parse('https://www.googleapis.com/youtube/v3/comments?part=snippet'),
                            headers: {
                              'Authorization': 'Bearer $_accessToken',
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reply posted successfully!')),
                            );
                            _fetchComments(); // Refresh list
                          } else {
                            throw Exception("Failed with status ${response.statusCode}: ${response.body}");
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to post reply: $e')),
                          );
                        }
                      },
                      child: const Text('Send Reply'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube AutoFunnel'),
        actions: [
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchComments,
              tooltip: 'Refresh Comments',
            ),
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleSignOut,
              tooltip: 'Disconnect YouTube',
            ),
        ],
      ),
      body: _currentUser == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.youtube_searched_for, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Connect your YouTube Channel\nto manage comments with AI.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _handleSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Connect with Google'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? const Center(child: Text('No comments found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final commentThread = _comments[index];
                        final snippet = commentThread['snippet']['topLevelComment']['snippet'];
                        final author = snippet['authorDisplayName'];
                        final text = snippet['textDisplay'];
                        final authorProfileUrl = snippet['authorProfileImageUrl'];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(authorProfileUrl),
                            ),
                            title: Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                            trailing: OutlinedButton(
                              onPressed: () => _showCommentDetails(commentThread),
                              child: const Text('Reply'),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }
}
