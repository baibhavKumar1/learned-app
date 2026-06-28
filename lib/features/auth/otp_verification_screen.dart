import 'package:flutter/material.dart';
import '../student/onboarding/student_onboarding_screen.dart';
import '../teacher/verification/teacher_verification_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String role;
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.role,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();

  void _verifyOtp() {
    if (widget.role == 'Student') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const StudentOnboardingScreen()), (route) => false);
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const TeacherVerificationScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Verification Code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a code to ${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verifyOtp,
                child: const Text('Verify & Continue'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Resend OTP logic
                },
                child: const Text('Didn\'t receive code? Resend'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
