import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../upload/upload_content_screen.dart';
import '../upload/manage_content_screen.dart';
import '../students/student_management_screen.dart';
import '../community/teacher_community_screen.dart';
import '../profile/teacher_profile_screen.dart';
import 'live_attempts_monitor_screen.dart';
import 'models/dashboard_models.dart';
import 'services/teacher_dashboard_service.dart';
import '../community/youtube_comments_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  final TeacherDashboardService _dashboardService = TeacherDashboardService();
  final String _teacherId = FirebaseAuth.instance.currentUser?.uid ?? 'test_teacher';

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildDashboardHomeContent(context),
      const TeacherCommunityScreen(),
      const StudentManagementScreen(),
      const ManageContentScreen(isEmbedded: true),
    ];

    final titles = [
      'Teacher Dashboard',
      'Community',
      'Student Management',
      'My Content',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSecondary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Content'),
        ],
      ),
      floatingActionButton: _buildSpeedDial(context),
    );
  }

  Widget _buildSpeedDial(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 12,
      spaceBetweenChildren: 8,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      elevation: 4,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      animationCurve: Curves.elasticInOut,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.video_library_outlined, color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          label: 'Upload Material / Video',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(
              body: SafeArea(child: UploadContentScreen(initialTabIndex: 0)),
            )));
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.lightbulb_outline, color: Colors.white),
          backgroundColor: Colors.amber.shade600,
          label: 'Post a Challenge',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(
              body: SafeArea(child: UploadContentScreen(initialTabIndex: 1)),
            )));
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.analytics_outlined, color: Colors.white),
          backgroundColor: Colors.pinkAccent,
          label: 'Monitor Live Attempts',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveAttemptsMonitorScreen()));
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.poll_outlined, color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          label: 'Create Poll',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poll creation coming soon...')));
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.youtube_searched_for, color: Colors.white),
          backgroundColor: Colors.red,
          label: 'YouTube AutoFunnel',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const YouTubeCommentsScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildDashboardHomeContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildHealthCard(context, 'Avg Score', '82%', Icons.analytics, Theme.of(context).colorScheme.secondary, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveAttemptsMonitorScreen()));
              })),
              const SizedBox(width: 12),
              Expanded(child: _buildHealthCard(context, 'Needs Help', '14', Icons.warning_amber_rounded, Colors.amber.shade600, () {
                setState(() => _selectedIndex = 2); // Jump to students tab
              })),
              const SizedBox(width: 12),
              Expanded(child: _buildHealthCard(context, 'Doubts', '5', Icons.question_answer_outlined, Colors.pinkAccent, () {
                setState(() => _selectedIndex = 1); // Jump to community tab
              })),
            ],
          ),
          const SizedBox(height: 32),

          // 2. Priority Action Items
          Text('Needs Your Attention', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 165,
            child: StreamBuilder<List<ActionItem>>(
              stream: _dashboardService.getActionItems(_teacherId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('All caught up!'));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    return _buildActionItemCard(context, item);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // 3. Recent Community Activity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text('View All'))
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<ActivityItem>>(
            stream: _dashboardService.getRecentActivity(_teacherId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No recent activity.'));
              }
              return Column(
                children: snapshot.data!.map((item) => _buildActivityItem(context, item)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context, String title, String value, IconData icon, Color accentColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 28),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItemCard(BuildContext context, ActionItem item) {
    IconData icon;
    Color color;

    switch (item.type) {
      case 'student_stuck':
        icon = Icons.trending_down;
        color = Colors.amber.shade600;
        break;
      case 'doubt':
        icon = Icons.forum_outlined;
        color = Colors.pinkAccent;
        break;
      case 'review_pending':
      default:
        icon = Icons.grading;
        color = Theme.of(context).colorScheme.primary;
        break;
    }

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                // Navigate based on item.type, then potentially mark as resolved
                // await _dashboardService.markActionItemResolved(_teacherId, item.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: ${item.actionText}')));
              },
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.1),
                foregroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(item.actionText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityItem item) {
    IconData icon;
    Color color;

    switch (item.type) {
      case 'upvote':
        icon = Icons.thumb_up_alt_outlined;
        color = Theme.of(context).colorScheme.secondary;
        break;
      case 'comment':
        icon = Icons.comment_outlined;
        color = Theme.of(context).colorScheme.primary;
        break;
      case 'discussion':
      default:
        icon = Icons.people_outline;
        color = Colors.pinkAccent;
        break;
    }

    final diff = DateTime.now().difference(item.timestamp);
    String timeString = '';
    if (diff.inDays > 0) {
      timeString = '${diff.inDays} d';
    } else if (diff.inHours > 0) {
      timeString = '${diff.inHours} h';
    } else if (diff.inMinutes > 0) {
      timeString = '${diff.inMinutes} m';
    } else {
      timeString = 'Now';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: Text(timeString, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
