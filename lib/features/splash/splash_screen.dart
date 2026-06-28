import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth/auth_screen.dart';
import '../auth/role_selection_screen.dart';
import '../student/home/student_home_screen.dart';
import '../student/onboarding/student_onboarding_screen.dart';
import '../teacher/dashboard/teacher_dashboard_screen.dart';
import '../teacher/verification/teacher_verification_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    // Wait for splash screen visual animation (e.g. 2 seconds)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _goToAuth();
      return;
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getUserProfile');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);

      if (!mounted) return;

      if (data['exists'] == true && data.containsKey('role')) {
        final role = data['role'];
        final onboardingComplete = data['onboardingComplete'] == true;

        if (onboardingComplete || role == 'Admin') {
          if (role == 'Admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          } else if (role == 'Student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
            );
          }
        } else {
          if (role == 'Student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentOnboardingScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TeacherVerificationScreen()),
            );
          }
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error fetching user profile during splash: $e');
      // If server fetch fails, fallback to standard auth screen
      _goToAuth();
    }
  }

  void _goToAuth() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/logo.svg', width: 100, height: 100,
                colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn)),
            const SizedBox(height: 16),
            Text(
              'EdTech Innovate',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
