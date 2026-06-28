import 'package:flutter/material.dart';

class DoubtsScreen extends StatelessWidget {
  const DoubtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: TabBar(
            tabs: [
              Tab(text: 'My Doubts'),
              Tab(text: 'Community Doubts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildDoubtCard(
                  context: context,
                  subject: 'Physics',
                  question: 'A ball is thrown vertically upward with a speed of 20 m/s. Find the maximum height it reaches?',
                  status: 'Teacher Reviewed',
                  isResolved: true,
                  time: '02:45',
                ),
                _buildDoubtCard(
                  context: context,
                  subject: 'Maths',
                  question: 'I am stuck at step 3 while solving this integration problem.',
                  status: 'Pending',
                  isResolved: false,
                  time: 'Just now',
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildDoubtCard(
                  context: context,
                  subject: 'Chemistry',
                  question: 'What is the hybridisation of xenon in XeF4?',
                  status: 'Resolved by Community',
                  isResolved: true,
                  time: '2 hours ago',
                ),
                _buildDoubtCard(
                  context: context,
                  subject: 'Physics',
                  question: 'Why does light bend when passing through a prism?',
                  status: '12 Replies',
                  isResolved: false,
                  time: '5 hours ago',
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PostQuestionScreen()));
          },
          backgroundColor: const Color(0xFF1976D2),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Post Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDoubtCard({
    required BuildContext context,
    required String subject,
    required String question,
    required String status,
    required bool isResolved,
    required String time,
  }) {
    return GestureDetector(
      onTap: isResolved ? () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtDetailScreen()));
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Attempted Doubt • $subject',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(isResolved ? Icons.check_circle : Icons.access_time, size: 16, color: isResolved ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(status, style: TextStyle(color: isResolved ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class PostQuestionScreen extends StatelessWidget {
  const PostQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Question', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('As Student', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
              initialValue: 'Physics',
              items: const [
                DropdownMenuItem(value: 'Physics', child: Text('Physics')),
                DropdownMenuItem(value: 'Maths', child: Text('Maths')),
              ],
              onChanged: (val) {},
            ),
            const SizedBox(height: 24),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Where I'm stuck:",
                hintText: "I got stuck at step 3 while solving this velocity problem.",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Upload Rough Work Photo', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.send),
              label: const Text('Post Question', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

class DoubtDetailScreen extends StatelessWidget {
  const DoubtDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Feedback', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Q: A ball is thrown vertically upward with a speed of 20 m/s. Find the maximum height it reaches?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // Mocking the rough work paper image. In a real app this would be an Image widget.
                    child: Container(
                      height: 300,
                      color: const Color(0xFFFDFDFD),
                      padding: const EdgeInsets.all(24),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('u = 20 m/s\nv = 0, at max height\n\nEnergy Conservation method\n1/2 m u^2 = 1/2 m v^2 + mgh\n1/2 x 20^2 = 0^2 + mgh\n\n0 + 10h = 400\nHence, h = 20m', style: TextStyle(fontFamily: 'Caveat', fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                  // Mocking the red ink annotation
                  Positioned(
                    top: 180,
                    right: 40,
                    child: Transform.rotate(
                      angle: -0.1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.yellow[200],
                          border: Border.all(color: Colors.red),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: const Text('Incorrect\nsign here', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    right: 120,
                    child: Container(
                      width: 60,
                      height: 30,
                      decoration: BoxDecoration(border: Border.all(color: Colors.red, width: 2), borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Color(0xFF1976D2)),
                  const SizedBox(width: 8),
                  const Icon(Icons.play_arrow, color: Color(0xFF1976D2)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      child: Row(
                        children: [
                          Container(width: 80, decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(2))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('00:45', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Re-attempt Question', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
