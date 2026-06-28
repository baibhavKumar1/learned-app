import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'edit_content_screen.dart';
import 'upload_content_screen.dart';
import 'in_app_video_player_screen.dart';
import 'create_course_screen.dart';

class ManageContentScreen extends StatelessWidget {
  final bool isEmbedded;

  const ManageContentScreen({super.key, this.isEmbedded = false});

  void _openCommentsPanel(BuildContext context, String docId, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Comments on: $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('course_materials')
                      .doc(docId)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading comments');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('No comments yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final commentData = docs[index].data() as Map<String, dynamic>;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: Colors.indigo),
                          ),
                          title: Text(commentData['studentName'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(commentData['commentText'] ?? '', style: const TextStyle(fontSize: 12)),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final bodyContent = uid == null
        ? const Center(child: Text('Not logged in'))
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('course_materials')
                .where('teacherId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs.toList() ?? [];
              
              // Sort locally by createdAt descending to avoid needing a Firestore composite index
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('You have not uploaded any content yet.'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(
                                body: SafeArea(child: UploadContentScreen(initialTabIndex: 0)),
                              )));
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Content'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen()));
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Create Course'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade50,
                              foregroundColor: Colors.indigo,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length + 1, // +1 for the upload button at the top
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(
                                  body: SafeArea(child: UploadContentScreen(initialTabIndex: 0)),
                                )));
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload Content'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.indigo.shade50,
                                foregroundColor: Colors.indigo,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen()));
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Create Course'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.indigo.shade50,
                                foregroundColor: Colors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = docs[index - 1].data() as Map<String, dynamic>;
                  final docId = docs[index - 1].id;
                  final isVisible = data['isVisible'] ?? true;
                  final isVideo = data['videoUrl'] != null;
                  
                  // Real analytics fields
                  final views = data['views'] ?? 0;
                  final likes = data['likesCount'] ?? 0;
                  final helpful = data['helpfulCount'] ?? 0;
                  final comments = data['commentsCount'] ?? 0;
                  final isSyllabusBased = data['isSyllabusBased'] ?? true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              isVideo ? Icons.video_library : Icons.picture_as_pdf,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(data['title'] ?? 'No title', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isSyllabusBased
                                    ? '${data['className']} • ${data['subject']}'
                                    : 'Extra / General Video'),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.visibility, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text('$views views', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('👍', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text('$likes likes', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('💡', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text('$helpful helpful', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.comment, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text('$comments comments', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVisible ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isVisible ? 'Visible' : 'Hidden',
                              style: TextStyle(
                                color: isVisible ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () async {
                                  final url = data['videoUrl'] ?? data['pdfUrl'];
                                  if (url != null) {
                                    if (isVideo) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InAppVideoPlayerScreen(
                                            videoUrl: url,
                                            title: data['title'] ?? 'Video',
                                          ),
                                        ),
                                      );
                                    } else {
                                      final uri = Uri.parse(url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } else {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    }
                                  }
                                },
                                icon: Icon(isVideo ? Icons.play_arrow : Icons.open_in_new),
                                label: Text(isVideo ? 'Play' : 'View PDF'),
                              ),
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade300),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => _openCommentsPanel(context, docId, data['title'] ?? 'Material'),
                                icon: const Icon(Icons.comment, size: 18),
                                label: const Text('Comment'),
                              ),
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade300),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditContentScreen(docId: docId, initialData: data),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );

    if (isEmbedded) {
      return bodyContent; // No Scaffold/AppBar when in BottomNav
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Content'),
      ),
      body: bodyContent,
    );
  }
}
