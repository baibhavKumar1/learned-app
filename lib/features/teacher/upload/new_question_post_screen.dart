import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewQuestionPostScreen extends StatefulWidget {
  const NewQuestionPostScreen({super.key});

  @override
  State<NewQuestionPostScreen> createState() => _NewQuestionPostScreenState();
}

class _NewQuestionPostScreenState extends State<NewQuestionPostScreen> {
  final _questionController = TextEditingController();
  final _chapterController = TextEditingController();
  final _timeController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  int _correctOptionIndex = 0;

  String _questionType = 'MCQ';
  String _subject = 'Physics';
  String _difficulty = 'Medium';

  bool _attemptFirstLock = true;
  bool _enableHints = true;
  bool _enablePeerVoting = true;
  bool _anonymousUntilSubmit = true;

  Future<void> _publishPost() async {
    final questionText = _questionController.text.trim();
    final chapterText = _chapterController.text.trim();

    if (questionText.isEmpty || chapterText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter question text and chapter title')),
      );
      return;
    }

    if (_questionType == 'MCQ') {
      if (_optionAController.text.trim().isEmpty ||
          _optionBController.text.trim().isEmpty ||
          _optionCController.text.trim().isEmpty ||
          _optionDController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all MCQ options')),
        );
        return;
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final teacherId = user?.uid ?? 'unknown_teacher';
      final teacherName = user?.displayName ?? 'Lumina Teacher';

      await FirebaseFirestore.instance.collection('challenges').add({
        'question': questionText,
        'type': _questionType,
        'subject': _subject,
        'chapter': chapterText,
        'difficulty': _difficulty,
        'timeMins': int.tryParse(_timeController.text.trim()) ?? 5,
        'attemptFirstLock': _attemptFirstLock,
        'enableHints': _enableHints,
        'enablePeerVoting': _enablePeerVoting,
        'anonymousUntilSubmit': _anonymousUntilSubmit,
        'options': _questionType == 'MCQ'
            ? [
                _optionAController.text.trim(),
                _optionBController.text.trim(),
                _optionCController.text.trim(),
                _optionDController.text.trim()
              ]
            : null,
        'correctOptionIndex': _questionType == 'MCQ' ? _correctOptionIndex : null,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'createdAt': FieldValue.serverTimestamp(),
        'hints': <String>[],
        'twists': '',
        'views': 0,
        'submitted': 0,
        'correctCount': 0,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question published successfully to Student Feed!')),
      );

      setState(() {
        _questionController.clear();
        _chapterController.clear();
        _timeController.clear();
        _optionAController.clear();
        _optionBController.clear();
        _optionCController.clear();
        _optionDController.clear();
        _correctOptionIndex = 0;
        _questionType = 'MCQ';
        _subject = 'Physics';
        _difficulty = 'Medium';
        _attemptFirstLock = true;
        _enableHints = true;
        _enablePeerVoting = true;
        _anonymousUntilSubmit = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish challenge: $e')),
      );
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _chapterController.dispose();
    _timeController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Question Type', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['MCQ', 'Numerical', 'Descriptive'].map((type) {
              final isSel = _questionType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSel,
                onSelected: (selected) => setState(() => _questionType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _questionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Question Text',
              hintText: 'Type the challenge details here...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          if (_questionType == 'MCQ') ...[
            const SizedBox(height: 16),
            const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _optionAController,
              decoration: const InputDecoration(
                labelText: 'Option A',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _optionBController,
              decoration: const InputDecoration(
                labelText: 'Option B',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _optionCController,
              decoration: const InputDecoration(
                labelText: 'Option C',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _optionDController,
              decoration: const InputDecoration(
                labelText: 'Option D',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Correct Option',
                border: OutlineInputBorder(),
              ),
              initialValue: _correctOptionIndex,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Option A')),
                DropdownMenuItem(value: 1, child: Text('Option B')),
                DropdownMenuItem(value: 2, child: Text('Option C')),
                DropdownMenuItem(value: 3, child: Text('Option D')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _correctOptionIndex = val);
                }
              },
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                  initialValue: _subject,
                  items: ['Physics', 'Chemistry', 'Mathematics', 'Biology']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _subject = val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _chapterController,
                  decoration: const InputDecoration(labelText: 'Chapter', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                  initialValue: _difficulty,
                  items: ['Easy', 'Medium', 'Hard']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _difficulty = val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: 'Attempt Time (mins)',
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Toggles & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Attempt-First Lock'),
            subtitle: const Text('Hide solution and feedback until attempted'),
            value: _attemptFirstLock,
            onChanged: (val) => setState(() => _attemptFirstLock = val),
          ),
          SwitchListTile(
            title: const Text('Enable Hints'),
            subtitle: const Text('Let students use step-by-step hints'),
            value: _enableHints,
            onChanged: (val) => setState(() => _enableHints = val),
          ),
          SwitchListTile(
            title: const Text('Enable Peer Voting'),
            subtitle: const Text('Allows Helpful, Clear, Smart tag votes'),
            value: _enablePeerVoting,
            onChanged: (val) => setState(() => _enablePeerVoting = val),
          ),
          SwitchListTile(
            title: const Text('Anonymous until submit'),
            subtitle: const Text('Hide names to promote fair evaluations'),
            value: _anonymousUntilSubmit,
            onChanged: (val) => setState(() => _anonymousUntilSubmit = val),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _publishPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Publish Challenge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
