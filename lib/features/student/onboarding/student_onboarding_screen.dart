import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/student_home_screen.dart';

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  State<StudentOnboardingScreen> createState() =>
      _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  String _selectedClass = '';
  String _selectedBoard = '';
  String _selectedGoal = '';
  final List<String> _selectedSubjects = [];

  final classes = ['10th', '11th', '12th'];
  final boards = ['CBSE', 'ICSE', 'State Board'];
  final goals = ['Engineering (JEE)', 'Medical (NEET)', 'Foundation'];
  final subjects = ['Mathematics', 'Physics', 'Chemistry', 'Biology'];

  Future<void> _completeOnboarding() async {
    if (_selectedClass.isEmpty ||
        _selectedBoard.isEmpty ||
        _selectedGoal.isEmpty ||
        _selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select all fields including subjects to continue',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'onboardingComplete': true,
            'className': _selectedClass,
            'board': _selectedBoard,
            'goal': _selectedGoal,
            'subjects': _selectedSubjects,
          });
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to Lumina!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us a bit about yourself to personalize your learning journey.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),

              Text(
                'Which class are you in?',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: classes
                    .map(
                      (c) => ChoiceChip(
                        label: Text(c),
                        selected: _selectedClass == c,
                        onSelected: (selected) =>
                            setState(() => _selectedClass = selected ? c : ''),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),

              Text(
                'Select your board',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: boards
                    .map(
                      (b) => ChoiceChip(
                        label: Text(b),
                        selected: _selectedBoard == b,
                        onSelected: (selected) =>
                            setState(() => _selectedBoard = selected ? b : ''),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),

              Text(
                'Select subjects of interest',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects
                    .map(
                      (s) => FilterChip(
                        label: Text(s),
                        selected: _selectedSubjects.contains(s),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSubjects.add(s);
                            } else {
                              _selectedSubjects.remove(s);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),

              Text(
                'What is your primary goal?',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: goals
                    .map(
                      (g) => ChoiceChip(
                        label: Text(g),
                        selected: _selectedGoal == g,
                        onSelected: (selected) =>
                            setState(() => _selectedGoal = selected ? g : ''),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
