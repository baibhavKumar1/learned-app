import 'package:flutter/material.dart';
import '../../core/theme/theme_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'App Preferences'),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) {
              final isDark = currentMode == ThemeMode.dark || 
                (currentMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
              
              return SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle between Light and Dark mode'),
                value: isDark,
                onChanged: (bool value) {
                  themeNotifier.toggleTheme(value);
                },
                secondary: const Icon(Icons.dark_mode_outlined),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Get alerts for classes and messages'),
            value: true,
            onChanged: (bool value) {},
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'About'),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0 (Build 10)'),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rate Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
