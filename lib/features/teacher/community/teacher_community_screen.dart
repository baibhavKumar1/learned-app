import 'package:flutter/material.dart';

class TeacherCommunityScreen extends StatefulWidget {
  const TeacherCommunityScreen({super.key});

  @override
  State<TeacherCommunityScreen> createState() => _TeacherCommunityScreenState();
}

class _TeacherCommunityScreenState extends State<TeacherCommunityScreen> {
  String _filter = 'All';

  final List<Map<String, dynamic>> _dummyPosts = [
    {
      'studentName': 'Alex Johnson',
      'subject': 'Physics',
      'excerpt': 'Why does the normal force not do work when an object slides down a ramp?',
      'status': 'Unanswered',
      'replies': 0,
    },
    {
      'studentName': 'Sneha Patil',
      'subject': 'Maths',
      'excerpt': 'Can someone explain the chain rule with a trigonometric example?',
      'status': 'Needs Verification',
      'replies': 3,
    },
    {
      'studentName': 'Karan Gupta',
      'subject': 'Physics',
      'excerpt': 'What is the difference between elastic and inelastic collision in 2D?',
      'status': 'Verified',
      'replies': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredPosts = _dummyPosts;
    if (_filter != 'All') {
      filteredPosts = _dummyPosts.where((post) => post['status'] == _filter).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Community Q&A',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              DropdownButton<String>(
                value: _filter,
                items: ['All', 'Unanswered', 'Needs Verification', 'Verified'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _filter = val!;
                  });
                },
                underline: const SizedBox(),
                icon: const Icon(Icons.filter_list, color: Color(0xFF1976D2)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              return _buildPostCard(post);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    Color statusColor = Colors.grey;
    if (post['status'] == 'Unanswered') statusColor = Colors.red;
    if (post['status'] == 'Needs Verification') statusColor = Colors.orange;
    if (post['status'] == 'Verified') statusColor = Colors.green;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: Colors.indigo, size: 16),
                ),
                const SizedBox(width: 8),
                Text('${post['studentName']} • ${post['subject']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post['status'],
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post['excerpt'],
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${post['replies']} Replies', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                TextButton(
                  onPressed: () {
                    _showPostDetails(post);
                  },
                  child: const Text('View Thread', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPostDetails(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thread', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  post['excerpt'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text('Posted by ${post['studentName']} • ${post['subject']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 24),
                const Text('Replies', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (post['replies'] == 0)
                  const Text('No replies yet. Be the first to answer!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                else
                  _buildMockReply(post),
                const Spacer(),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Type your authoritative answer...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF1976D2)),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answer posted and marked as Verified!')));
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMockReply(Map<String, dynamic> post) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text('Anon_Student_42', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('I think the chain rule means you take the derivative of the outside function, then multiply by the derivative of the inside.', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          if (post['status'] == 'Needs Verification')
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answer Verified! +50 XP awarded to student.')));
              },
              icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
              label: const Text('Verify this Answer', style: TextStyle(color: Colors.green)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            )
          else if (post['status'] == 'Verified')
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text('Verified by Teacher', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
    );
  }
}
