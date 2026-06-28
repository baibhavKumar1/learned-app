import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentFeedScreen extends StatefulWidget {
  const StudentFeedScreen({super.key});

  @override
  State<StudentFeedScreen> createState() => _StudentFeedScreenState();
}

class _StudentFeedScreenState extends State<StudentFeedScreen> {
  List<QueryDocumentSnapshot> _challenges = [];
  Map<String, Map<String, dynamic>> _attempts = {};
  bool _loading = true;
  StreamSubscription? _challengesSub;
  StreamSubscription? _attemptsSub;

  @override
  void initState() {
    super.initState();
    _subscribeToData();
  }

  void _subscribeToData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    _attemptsSub = FirebaseFirestore.instance
        .collection('challenge_attempts')
        .where('studentId', isEqualTo: uid)
        .snapshots()
        .listen((attemptsSnap) {
      final Map<String, Map<String, dynamic>> attemptsMap = {};
      for (var doc in attemptsSnap.docs) {
        final data = doc.data();
        attemptsMap[data['challengeId']] = data;
      }
      if (mounted) {
        setState(() {
          _attempts = attemptsMap;
          if (_challengesSub == null) {
            _subscribeToChallenges();
          } else {
            _loading = false;
          }
        });
      }
    });
  }

  void _subscribeToChallenges() {
    _challengesSub = FirebaseFirestore.instance
        .collection('challenges')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((challengesSnap) {
      if (mounted) {
        setState(() {
          _challenges = challengesSnap.docs;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _challengesSub?.cancel();
    _attemptsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final unattempted = _challenges.where((c) => !_attempts.containsKey(c.id)).toList();
    final attempted = _challenges.where((c) => _attempts.containsKey(c.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Daily Feed',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 16),
          if (unattempted.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('All challenges attempted! Check the Learning Trail below.', textAlign: TextAlign.center),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unattempted.length,
              separatorBuilder: (_, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doc = unattempted[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildLockedFeedCard(
                  context,
                  challengeId: doc.id,
                  challengeData: data,
                );
              },
            ),
          const SizedBox(height: 32),
          const Text(
            'Your Learning Trail',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 16),
          if (attempted.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Attempt challenges to build your Learning Trail!', textAlign: TextAlign.center),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attempted.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = attempted[index];
                final data = doc.data() as Map<String, dynamic>;
                final attemptData = _attempts[doc.id]!;
                return _buildTrailCard(
                  context,
                  challengeId: doc.id,
                  challengeData: data,
                  attemptData: attemptData,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLockedFeedCard(
    BuildContext context, {
    required String challengeId,
    required Map<String, dynamic> challengeData,
  }) {
    final teacherName = challengeData['teacherName'] ?? 'Lumina Teacher';
    final subject = challengeData['subject'] ?? 'General';
    final difficulty = challengeData['difficulty'] ?? 'Medium';
    final timeMins = challengeData['timeMins'] ?? 5;
    final question = challengeData['question'] ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text('$teacherName • $subject', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 4),
            Text('$difficulty • $timeMins min', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Text(
              question,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Attempt required to unlock answers',
                    style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedDetailScreen(
                        challengeId: challengeId,
                        challengeData: challengeData,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Attempt to Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailCard(
    BuildContext context, {
    required String challengeId,
    required Map<String, dynamic> challengeData,
    required Map<String, dynamic> attemptData,
  }) {
    final teacherName = challengeData['teacherName'] ?? 'Lumina Teacher';
    final subject = challengeData['subject'] ?? 'General';
    final question = challengeData['question'] ?? '';
    final isCorrect = attemptData['isCorrect'] ?? false;
    final hasExplanation = attemptData['explanation'] != null;

    final status = hasExplanation ? 'Explained to others' : 'Attempted';
    final statusColor = hasExplanation ? Colors.green : Colors.orange;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 8),
                Text('$teacherName • $subject', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedDetailScreen(
                          challengeId: challengeId,
                          challengeData: challengeData,
                        ),
                      ),
                    );
                  },
                  child: const Text('Review Discussion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCorrect ? 'Correct' : 'Incorrect',
                      style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeedDetailScreen extends StatefulWidget {
  final String challengeId;
  final Map<String, dynamic> challengeData;
  const FeedDetailScreen({
    super.key,
    required this.challengeId,
    required this.challengeData,
  });

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  int? _selectedOption;
  double _confidence = 50;
  bool _isSubmitting = false;
  bool _showSolutions = false;
  int _revealedHintsCount = 0;
  final _explanationController = TextEditingController();
  final _textAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('challenges')
        .doc(widget.challengeId)
        .update({'views': FieldValue.increment(1)})
        .catchError((_) {});
  }

  @override
  void dispose() {
    _explanationController.dispose();
    _textAnswerController.dispose();
    super.dispose();
  }

  Future<void> _submitAttempt() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final isMcq = widget.challengeData['type'] == 'MCQ';
    if (isMcq && _selectedOption == null) return;
    if (!isMcq && _textAnswerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final studentName = userSnap.data()?['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous Student';

      bool isCorrect = false;
      if (isMcq) {
        isCorrect = _selectedOption == widget.challengeData['correctOptionIndex'];
      } else {
        isCorrect = true;
      }

      final attemptDocRef = FirebaseFirestore.instance
          .collection('challenge_attempts')
          .doc('${uid}_${widget.challengeId}');

      await attemptDocRef.set({
        'challengeId': widget.challengeId,
        'studentId': uid,
        'studentName': studentName,
        'selectedOption': _selectedOption,
        'textAnswer': isMcq ? null : _textAnswerController.text.trim(),
        'confidence': _confidence,
        'isCorrect': isCorrect,
        'explanation': null,
        'createdAt': FieldValue.serverTimestamp(),
        'votes': {'helpful': 0, 'clear': 0, 'smart': 0},
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'xp': FieldValue.increment(10),
      }).catchError((_) {});

      await FirebaseFirestore.instance.collection('challenges').doc(widget.challengeId).update({
        'submitted': FieldValue.increment(1),
        if (isCorrect) 'correctCount': FieldValue.increment(1),
      }).catchError((_) {});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attempt submitted! +10 XP earned. Answers unlocked! ${isCorrect ? "Correct!" : "Incorrect."}')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit attempt: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitExplanation(String docId) async {
    final text = _explanationController.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('challenge_attempts')
          .doc(docId)
          .update({'explanation': text});

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'xp': FieldValue.increment(5),
      }).catchError((_) {});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Explanation published! +5 XP earned.')),
      );
      _explanationController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit explanation: $e')),
        );
      }
    }
  }

  Future<void> _voteExplanation(String docId, String voteType) async {
    try {
      await FirebaseFirestore.instance
          .collection('challenge_attempts')
          .doc(docId)
          .update({'votes.$voteType': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Failed to vote: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('User not authenticated')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('challenges').doc(widget.challengeId).snapshots(),
      builder: (context, challengeSnap) {
        if (!challengeSnap.hasData || !challengeSnap.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Attempt Challenge')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final challengeData = challengeSnap.data!.data() as Map<String, dynamic>;
        final questionText = challengeData['question'] ?? '';
        final options = List<String>.from(challengeData['options'] ?? []);
        final correctOptionIndex = challengeData['correctOptionIndex'] as int?;
        final twistText = challengeData['twists'] as String?;
        final hints = List<String>.from(challengeData['hints'] ?? []);
        final enableHints = challengeData['enableHints'] ?? true;
        final type = challengeData['type'] ?? 'MCQ';

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('challenge_attempts')
              .doc('${uid}_${widget.challengeId}')
              .snapshots(),
          builder: (context, attemptSnap) {
            final hasAttempted = attemptSnap.hasData && attemptSnap.data!.exists;
            Map<String, dynamic>? attemptData;
            bool isCorrect = false;
            int? userSelectedOption;

            if (hasAttempted) {
              attemptData = attemptSnap.data!.data() as Map<String, dynamic>;
              isCorrect = attemptData['isCorrect'] ?? false;
              userSelectedOption = attemptData['selectedOption'] as int?;
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Attempt Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
                elevation: 1,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            challengeData['subject'] ?? 'General',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          challengeData['chapter'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Q: $questionText',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
                    ),
                    const SizedBox(height: 24),

                    if (twistText != null && twistText.trim().isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.bolt, color: Colors.deepOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Active Twist / Follow-up', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                  const SizedBox(height: 4),
                                  Text(twistText, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (type == 'MCQ') ...[
                      ...List.generate(options.length, (index) {
                        final isSelected = (hasAttempted ? userSelectedOption : _selectedOption) == index;
                        final isCorrectOption = correctOptionIndex == index;

                        Color borderC = Colors.grey.withValues(alpha: 0.3);
                        Color bgC = Colors.white;

                        if (hasAttempted) {
                          if (isCorrectOption) {
                            borderC = Colors.green;
                            bgC = Colors.green.withValues(alpha: 0.05);
                          } else if (isSelected) {
                            borderC = Colors.red;
                            bgC = Colors.red.withValues(alpha: 0.05);
                          }
                        } else if (isSelected) {
                          borderC = const Color(0xFF1976D2);
                          bgC = const Color(0xFF1976D2).withValues(alpha: 0.02);
                        }

                        return GestureDetector(
                          onTap: hasAttempted ? null : () => setState(() => _selectedOption = index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: bgC,
                              border: Border.all(color: borderC, width: isSelected || (hasAttempted && isCorrectOption) ? 2 : 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? const Color(0xFF1976D2) : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(options[index], style: const TextStyle(fontSize: 16))),
                                if (hasAttempted && isCorrectOption)
                                  const Icon(Icons.check_circle, color: Colors.green)
                                else if (hasAttempted && isSelected)
                                  const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      if (!hasAttempted) ...[
                        TextField(
                          controller: _textAnswerController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Enter your answer',
                            hintText: 'Type your final answer or solution here...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.05),
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Your Answer: ${attemptData?["textAnswer"] ?? ""}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                    const SizedBox(height: 24),

                    if (!hasAttempted) ...[
                      const Text('How confident are you?', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('0%'),
                          Expanded(
                            child: Slider(
                              value: _confidence,
                              min: 0,
                              max: 100,
                              divisions: 10,
                              label: '${_confidence.round()}%',
                              onChanged: (val) => setState(() => _confidence = val),
                            ),
                          ),
                          const Text('100%'),
                          const SizedBox(width: 8),
                          Text(
                            _confidence < 30 ? '😰' : _confidence < 70 ? '🙂' : '😎',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitAttempt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Submit Attempt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isCorrect ? Border.all(color: Colors.green) : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.check_circle, color: isCorrect ? Colors.green : Colors.grey, size: 48),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Correct!',
                                        style: TextStyle(
                                          color: isCorrect ? Colors.green[800] : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Confidence ${attemptData?["confidence"]?.round()}%', style: const TextStyle(fontSize: 12)),
                                      const Text('Accuracy 100%', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: !isCorrect ? Colors.red.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: !isCorrect ? Border.all(color: Colors.red) : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.cancel, color: !isCorrect ? Colors.red : Colors.grey, size: 48),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Incorrect',
                                        style: TextStyle(
                                          color: !isCorrect ? Colors.red[800] : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Confidence ${attemptData?["confidence"]?.round()}%', style: const TextStyle(fontSize: 12)),
                                      const Text('Accuracy 0%', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (!_showSolutions) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => setState(() => _showSolutions = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('View Solutions & Discussion', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ] else ...[
                            _buildSolutionsView(attemptSnap.data!.id, isCorrect, challengeData),
                          ],
                          const SizedBox(height: 12),
                          if (enableHints && hints.isNotEmpty) ...[
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('Need a Hint?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                    const SizedBox(height: 8),
                                    ...List.generate(_revealedHintsCount, (hIdx) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('Hint ${hIdx + 1}: ${hints[hIdx]}', style: const TextStyle(fontSize: 13)),
                                      );
                                    }),
                                    if (_revealedHintsCount < hints.length)
                                      TextButton(
                                        onPressed: () => setState(() => _revealedHintsCount++),
                                        child: Text(_revealedHintsCount == 0 ? 'Reveal First Hint' : 'Reveal Next Hint'),
                                      )
                                    else
                                      const Text('All hints revealed!', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSolutionsView(String attemptDocId, bool isCorrect, Map<String, dynamic> challengeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Top Student Solutions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('challenge_attempts')
              .where('challengeId', isEqualTo: widget.challengeId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allDocs = snapshot.data!.docs;
            final docs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              final explanation = data?['explanation'] as String?;
              return explanation != null && explanation.trim().isNotEmpty;
            }).toList();

            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No student explanations yet. Be the first to share your steps!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              );
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final votes = Map<String, int>.from(data['votes'] ?? {'helpful': 0, 'clear': 0, 'smart': 0});
                return _buildSolutionItem(docId, data, votes);
              }).toList(),
            );
          },
        ),
        const Divider(height: 32),
        const Text("Solution Explanation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.withValues(alpha: 0.05),
          child: Text(
            challengeData['solutionExplanation'] ?? 'Correct Option: Option ${String.fromCharCode(65 + (challengeData["correctOptionIndex"] as num? ?? 0).toInt())}',
          ),
        ),
        const SizedBox(height: 24),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('challenge_attempts').doc(attemptDocId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final explanation = data['explanation'] as String?;

            if (explanation != null && explanation.isNotEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Explanation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),
                    Text(explanation),
                    const SizedBox(height: 8),
                    const Text('+5 XP earned!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Explain in Your Own Words (earn +5 XP)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _explanationController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type your explanation here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Earn +5 XP', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: () => _submitExplanation(attemptDocId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Submit Explanation'),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildSolutionItem(String docId, Map<String, dynamic> data, Map<String, int> votes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 8),
                Text(data['studentName'] ?? 'Anonymous Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (data['isCorrect'] ?? false)
                  const Icon(Icons.check, color: Colors.green, size: 16)
                else
                  const Icon(Icons.close, color: Colors.red, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(data['explanation'] ?? '', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Vote:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                _voteTag(docId, 'helpful', '👍 Helpful (${votes["helpful"]})', Colors.blue),
                const SizedBox(width: 8),
                _voteTag(docId, 'clear', '✨ Clear (${votes["clear"]})', Colors.amber),
                const SizedBox(width: 8),
                _voteTag(docId, 'smart', '🎯 Smart (${votes["smart"]})', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _voteTag(String docId, String type, String label, Color color) {
    return GestureDetector(
      onTap: () => _voteExplanation(docId, type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
