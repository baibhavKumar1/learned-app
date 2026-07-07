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
import '../../settings/settings_screen.dart';
import 'widgets/brutalist_mini_player.dart';

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

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return 'Student Home';
      case 1: return 'Syllabus';
      case 2: return 'Doubts';
      case 3: return 'Learning Feed';
      case 4: return 'Settings';
      default: return 'Edtech Innovate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: const Icon(Icons.search, size: 26),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {},
                child: const Icon(Icons.notifications_outlined, size: 26),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                  );
                },
                child: const Icon(Icons.person_outline, size: 26),
              ),
              const SizedBox(width: 16),
            ],
          )
        ],
      ),
      body: [
        _buildHomeContent(context),
        const SyllabusScreen(),
        const DoubtsScreen(),
        const StudentFeedScreen(),
        const SettingsScreen(),
      ][_selectedIndex],
      drawer: _buildDrawer(),
      bottomNavigationBar: const BrutalistMiniPlayer(),
    );
  }

  Widget _buildDrawer() {
    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Text(
            'Edtech Innovate',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: Text('Syllabus'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.question_answer_outlined),
          selectedIcon: Icon(Icons.question_answer),
          label: Text('Doubts'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.dynamic_feed_outlined),
          selectedIcon: Icon(Icons.dynamic_feed),
          label: Text('Feed'),
        ),
        const Divider(indent: 28, endIndent: 28),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
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
            height: 120,
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
            onTap: () => setState(() => _selectedIndex = 3),
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
          height: 220,
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
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage('https://picsum.photos/seed/video${index + 10}/300/450'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      // Gradient
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 120,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                      ),
                      // Lock Overlay if not unlocked
                      if (!isUnlocked)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: const Center(
                              child: Icon(Icons.lock, color: Colors.white70, size: 40),
                            ),
                          ),
                        ),
                      // Content
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isUnlocked)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                              ),
                            Text(
                              data['title'] ?? 'Untitled Video',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, height: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isFree ? 'Free' : 'Premium',
                              style: TextStyle(
                                color: isUnlocked ? Colors.greenAccent : Colors.amber,
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
          Text(
            'Advanced Mathematics',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Chapter 4: Calculus Basics',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.6,
            backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
          ),
          const SizedBox(height: 8),
          Text('60% Completed', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, int index) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage('https://picsum.photos/seed/science/500/300'), // Reliable placeholder
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Typography
          Text(
            'Physics 10${index + 1}', 
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 14,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Mechanics & Motion', 
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), 
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(BuildContext context, int index) {
    final trending = [
      {'name': 'Organic Chemistry Hacks', 'views': '12k views'},
      {'name': 'Newton\'s Laws Simplified', 'views': '9k views'},
      {'name': 'Electrostatics Masterclass', 'views': '8.5k views'},
      {'name': 'Trigonometry Tricks', 'views': '7.2k views'},
    ];
    final item = trending[index % trending.length];   
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Watermark number clipped to bottom right
          Positioned(
            right: 5,
            bottom: -5,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                height: 1.0,
                letterSpacing: -5,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, height: 1.3),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      item['views'] as String,
                      style: TextStyle(
                        color: Colors.orange.shade700, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

}
