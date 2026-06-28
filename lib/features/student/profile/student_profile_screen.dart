import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../subscription/plan_selection_screen.dart';
import '../../auth/linked_accounts_screen.dart';
import 'saved_content_screen.dart';
import 'edit_preferences_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Lumina Student';
    final email = user?.email ?? 'No email provided';
    final photoUrl = user?.photoURL ?? 'https://i.pravatar.cc/150?img=11';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(photoUrl),
          ),
          const SizedBox(height: 16),
          Text(displayName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(email,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 32),
          _buildStatRow(context),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Achievements'),
          const SizedBox(height: 16),
          _buildAchievementsList(),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Settings & Preferences'),
          const SizedBox(height: 16),
          _buildSettingsList(context),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(context, 'Hours Learned', '124'),
        _buildStatCard(context, 'Tests Taken', '14'),
        _buildStatCard(context, 'Rank', '#42'),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAchievementsList() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildBadge(Icons.local_fire_department, '7 Day Streak', Colors.orange),
          _buildBadge(Icons.star, 'Top 10%', Colors.amber),
          _buildBadge(Icons.speed, 'Fast Learner', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Edit Profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Edit Profile',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const TextField(
                        decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Save Details'),
                    )
                  ],
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.tune_outlined),
          title: const Text('Update Preferences'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditPreferencesScreen()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.bookmark_outline),
          title: const Text('Saved Content'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SavedContentScreen()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.subscriptions_outlined),
          title: const Text('My Subscription'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlanSelectionScreen()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.link),
          title: const Text('Linked Accounts'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LinkedAccountsScreen()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Support Desk'),
                content: const Text(
                    'Need help? Drop an email to support@edtechinnovate.com. We answer within 2 hours!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  )
                ],
              ),
            );
          },
        ),
        ListTile(
          leading:
              Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
          title: Text('Sign Out',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error)),
          onTap: () async {
            try {
              await GoogleSignIn().signOut();
            } catch (_) {}
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
        ),
      ],
    );
  }
}
