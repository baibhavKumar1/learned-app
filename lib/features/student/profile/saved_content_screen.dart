import 'package:flutter/material.dart';

class SavedContentScreen extends StatelessWidget {
  const SavedContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedItems = [
      {'title': 'Calculus Formula Sheet', 'type': 'PDF Notes', 'date': 'Saved 3 days ago'},
      {'title': 'Introduction to Derivatives', 'type': 'Video Lecture', 'date': 'Saved 1 week ago'},
      {'title': 'Organic Chemistry Hacks', 'type': 'Video Lecture', 'date': 'Saved 1 week ago'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Content', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: savedItems.isEmpty
          ? const Center(
              child: Text('No saved content yet.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedItems.length,
              itemBuilder: (context, index) {
                final item = savedItems[index];
                final isVideo = item['type'] == 'Video Lecture';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isVideo
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isVideo ? Icons.play_circle_outline : Icons.description_outlined,
                        color: isVideo ? Colors.red : Colors.blue,
                      ),
                    ),
                    title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item['type']} • ${item['date']}'),
                    trailing: const Icon(Icons.download_done, color: Colors.green),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening ${item['title']}')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
