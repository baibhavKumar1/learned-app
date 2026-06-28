import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LinkedAccountsScreen extends StatefulWidget {
  const LinkedAccountsScreen({super.key});

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  bool _isLoading = false;

  List<String> get _linkedProviders =>
      FirebaseAuth.instance.currentUser?.providerData
          .map((p) => p.providerId)
          .toList() ??
      [];

  bool get _hasGoogle => _linkedProviders.contains('google.com');
  bool get _hasPassword => _linkedProviders.contains('password');

  Future<void> _linkGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn().signOut();
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
      if (mounted) {
        setState(() {});
        _showSuccess('Google account linked successfully!');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _showError('This Google account is already linked to another user.');
      } else {
        _showError(e.message ?? 'Failed to link Google account.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlinkGoogle() async {
    if (!_hasPassword) {
      _showError(
          'Set a password first before unlinking Google to avoid losing access.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser!.unlink('google.com');
      if (mounted) {
        setState(() {});
        _showSuccess('Google account unlinked.');
      }
    } catch (_) {
      _showError('Failed to unlink Google account.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _linkEmailPassword() async {
    final emailCtrl = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email ?? '',
    );
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Email & Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a password so you can also sign in with email.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: 'Password (min 6 chars)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final cred = EmailAuthProvider.credential(
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                );
                await FirebaseAuth.instance.currentUser!
                    .linkWithCredential(cred);
                if (mounted) {
                  setState(() {});
                  _showSuccess('Email & password linked successfully!');
                }
              } on FirebaseAuthException catch (e) {
                _showError(e.message ?? 'Failed to link email/password.');
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _unlinkPassword() async {
    if (!_hasGoogle) {
      _showError('You must keep at least one sign-in method linked.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser!.unlink('password');
      if (mounted) {
        setState(() {});
        _showSuccess('Email & password sign-in removed.');
      }
    } catch (_) {
      _showError('Failed to unlink email/password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(20),
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Linked Accounts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Manage how you sign in to your account.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                _ProviderTile(
                  icon: Icons.g_mobiledata_rounded,
                  iconColor: Colors.red.shade600,
                  title: 'Google',
                  subtitle: _hasGoogle ? 'Linked' : 'Not linked',
                  isLinked: _hasGoogle,
                  onAction: _hasGoogle ? _unlinkGoogle : _linkGoogle,
                  actionLabel: _hasGoogle ? 'Unlink' : 'Link',
                ),
                const SizedBox(height: 16),
                _ProviderTile(
                  icon: Icons.lock_outline,
                  iconColor: Colors.blueGrey,
                  title: 'Email & Password',
                  subtitle: _hasPassword ? 'Linked' : 'Not set',
                  isLinked: _hasPassword,
                  onAction:
                      _hasPassword ? _unlinkPassword : _linkEmailPassword,
                  actionLabel: _hasPassword ? 'Remove' : 'Set Password',
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keep at least one sign-in method linked to avoid being locked out.',
                          style: TextStyle(
                              color: Colors.amber.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLinked;
  final VoidCallback onAction;
  final String actionLabel;

  const _ProviderTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLinked,
    required this.onAction,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLinked
              ? Colors.green.shade200
              : Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isLinked
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 13,
                      color: isLinked ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: isLinked ? Colors.green : Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: isLinked
                  ? Colors.red.shade600
                  : Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: isLinked
                    ? Colors.red.shade200
                    : Theme.of(context).colorScheme.primary,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
