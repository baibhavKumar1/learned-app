import 'package:flutter/material.dart';
import 'video_page.dart';
import 'chapter_test_screen.dart';

class TopicListScreen extends StatelessWidget {
  final String chapterTitle;
  const TopicListScreen({super.key, required this.chapterTitle});

  @override
  Widget build(BuildContext context) {
    final topics = [
      {
        'title': 'Introduction to Rates of Change',
        'duration': '12 min',
        'completed': true,
        'docId': 'rates_of_change',
        'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'description': 'Learn the fundamentals of rates of change.',
        'isFree': true,
        'price': 0,
      },
      {
        'title': 'The Limit Definition of Derivative',
        'duration': '18 min',
        'completed': true,
        'docId': 'limit_definition',
        'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'description': 'Understand how limits define derivatives.',
        'isFree': true,
        'price': 0,
      },
      {
        'title': 'Power Rule and Constant Rule',
        'duration': '15 min',
        'completed': false,
        'docId': 'power_rule',
        'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'description': 'Master the power rule and constant rule.',
        'isFree': true,
        'price': 0,
      },
      {
        'title': 'Product and Quotient Rules',
        'duration': '22 min',
        'completed': false,
        'docId': 'product_quotient',
        'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'description': 'Explore product and quotient rule derivations.',
        'isFree': true,
        'price': 0,
      },
      {
        'title': 'Chain Rule Basics',
        'duration': '20 min',
        'completed': false,
        'docId': 'chain_rule',
        'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'description': 'Discover the chain rule for composite functions.',
        'isFree': true,
        'price': 0,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(chapterTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
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
                        color: (topic['completed'] as bool)
                            ? Colors.green.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (topic['completed'] as bool) ? Icons.check : Icons.play_arrow,
                        color: (topic['completed'] as bool)
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(topic['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(topic['duration'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPage(
                            docId: topic['docId'] as String,
                            topicTitle: topic['title'] as String,
                            chapterTitle: chapterTitle,
                            videoUrl: topic['videoUrl'] as String,
                            description: topic['description'] as String,
                            isFree: topic['isFree'] as bool,
                            price: topic['price'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChapterTestScreen(chapterTitle: chapterTitle),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Take Chapter Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
