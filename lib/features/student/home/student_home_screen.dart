import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../syllabus/syllabus_screen.dart';
import '../doubts/doubts_screen.dart';
import '../profile/student_profile_screen.dart';
import '../feed/student_feed_screen.dart';
import '../search/search_screen.dart';
import '../syllabus/video_page.dart';
import '../subscription/plan_selection_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  String? _userPlan;
  String? _userClass;
  List<String> _userSubjects = [];

  @override
  void initState() {
    super.initState();
    _fetchUserPlan();
  }

  Future<void> _fetchUserPlan() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userPlan = userDoc.data()?['plan'];
          _userClass = userDoc.data()?['className'];
          if (userDoc.data()?['subjects'] != null) {
            _userSubjects = List<String>.from(userDoc.data()?['subjects']);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              setState(() => _selectedIndex = 3);
            },
          )
        ],
      ),
      body: [
        _buildHomeContent(context),
        const SyllabusScreen(),
        const DoubtsScreen(),
        const StudentProfileScreen(),
        const StudentFeedScreen(),
      ][_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Lumina App',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Syllabus'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: const Text('Doubts'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dynamic_feed),
              title: const Text('Learning Feed'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Continue Learning', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildProgressCard(context),
          const SizedBox(height: 32),
          Text('Recommended Courses', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) => _buildCourseCard(context, index),
            ),
          ),
          const SizedBox(height: 32),
          Text('Trending Now', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) => _buildTrendingCard(context, index),
            ),
          ),
          const SizedBox(height: 32),
          Text('Extra Learning Videos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildExtraVideosList(context),
          const SizedBox(height: 32),
          Text('Daily Learning Feed', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Try the new Next-Gen Feed!', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text('Attempt locked questions, see peer approaches, and learn faster.', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraVideosList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('course_materials')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading extra videos');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        
        // Filter for videos that are NOT syllabus based (courseId is null or isSyllabusBased != true)
        var videos = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final hasVideo = data['videoUrl'] != null;
          final isSyllabus = data['isSyllabusBased'] == true || data['courseId'] != null;
          return hasVideo && !isSyllabus;
        }).toList();

        // Filter based on user preferences (Class & Subject) if available
        if (videos.isNotEmpty && ((_userClass != null && _userClass!.isNotEmpty) || _userSubjects.isNotEmpty)) {
          final filtered = videos.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final contentClass = data['className'];
            final contentSubject = data['subject'];
            
            final matchesClass = _userClass == null || 
                                 _userClass!.isEmpty || 
                                 contentClass == _userClass || 
                                 contentClass == 'General';
            
            final matchesSubject = _userSubjects.isEmpty || 
                                   _userSubjects.contains(contentSubject) || 
                                   contentSubject == 'General';
            
            return matchesClass && matchesSubject;
          }).toList();

          if (filtered.isNotEmpty) {
            videos = filtered;
          }
        }

        if (videos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No extra videos available.', style: TextStyle(color: Colors.grey)),
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final data = videos[index].data() as Map<String, dynamic>;
              final isFree = data['isFree'] ?? true;
              final price = data['price'] ?? 0;
              final hasPlan = _userPlan != null && _userPlan!.isNotEmpty;
              final isUnlocked = isFree || hasPlan;

              return GestureDetector(
                onTap: () {
                  if (!isUnlocked) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Premium Content', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('This video is premium. Please select a plan to unlock all videos and notes.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
                              );
                            },
                            child: const Text('View Plans'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPage(
                        docId: videos[index].id,
                        topicTitle: data['title'] ?? 'Lecture',
                        chapterTitle: 'Extra Learning',
                        videoUrl: data['videoUrl'] ?? '',
                        pdfUrl: data['pdfUrl'],
                        pdfFileName: data['pdfFileName'],
                        description: data['description'] ?? '',
                        isFree: isFree,
                        price: price,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Icon(
                            isUnlocked ? Icons.play_circle_fill : Icons.lock,
                            color: isUnlocked ? Theme.of(context).colorScheme.primary : Colors.amber,
                            size: 40,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'Untitled Video',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isFree ? 'Free' : 'Premium',
                              style: TextStyle(
                                color: isUnlocked ? Colors.green : Colors.amber.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Mathematics',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chapter 4: Calculus Basics',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.6,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
          ),
          const SizedBox(height: 8),
          const Text('60% Completed', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, int index) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(child: Icon(Icons.science, size: 40)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Physics 10${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(BuildContext context, int index) {
    final trending = [
      {'name': 'Organic Chemistry Hacks', 'views': '12k views', 'icon': Icons.bubble_chart},
      {'name': 'Newton\'s Laws Simplified', 'views': '9k views', 'icon': Icons.insights},
      {'name': 'Electrostatics Masterclass', 'views': '8.5k views', 'icon': Icons.bolt},
      {'name': 'Trigonometry Tricks', 'views': '7.2k views', 'icon': Icons.architecture},
    ];
    final item = trending[index % trending.length];
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(child: Icon(item['icon'] as IconData, color: Theme.of(context).colorScheme.secondary, size: 40)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(item['views'] as String, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
