import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveAttemptsMonitorScreen extends StatefulWidget {
  const LiveAttemptsMonitorScreen({super.key});

  @override
  State<LiveAttemptsMonitorScreen> createState() => _LiveAttemptsMonitorScreenState();
}

class _LiveAttemptsMonitorScreenState extends State<LiveAttemptsMonitorScreen> {
  void _addHint(String challengeId, List<String> currentHints) {
    showDialog(
      context: context,
      builder: (context) {
        final hintController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Hint to Question'),
          content: TextField(
            controller: hintController,
            decoration: const InputDecoration(labelText: 'Hint Text', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final hintText = hintController.text.trim();
                if (hintText.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance.collection('challenges').doc(challengeId).update({
                      'hints': FieldValue.arrayUnion([hintText])
                    });
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hint added successfully!')),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error adding hint: $e');
                  }
                }
              },
              child: const Text('Add Hint'),
            ),
          ],
        );
      },
    );
  }

  void _addTwist(String challengeId, String? currentTwist) {
    showDialog(
      context: context,
      builder: (context) {
        final twistController = TextEditingController(text: currentTwist);
        return AlertDialog(
          title: const Text('Add/Change Question Twist'),
          content: TextField(
            controller: twistController,
            decoration: const InputDecoration(labelText: 'Twist/Follow-up Question', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final twistText = twistController.text.trim();
                try {
                  await FirebaseFirestore.instance.collection('challenges').doc(challengeId).update({
                    'twists': twistText
                  });
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Question twist updated!')),
                    );
                  }
                } catch (e) {
                  debugPrint('Error updating twist: $e');
                }
              },
              child: const Text('Publish Twist'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('User not authenticated')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attempts Monitor'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('challenges')
            .where('teacherId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, challengesSnap) {
          if (challengesSnap.hasError) {
            return Center(child: Text('Error: ${challengesSnap.error}'));
          }
          if (!challengesSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = challengesSnap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No challenges published yet. Click "+" to create one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final challengeDoc = docs[index];
              final challengeId = challengeDoc.id;
              final q = challengeDoc.data() as Map<String, dynamic>;

              final questionText = q['question'] ?? '';
              final hints = List<String>.from(q['hints'] ?? []);
              final twistText = q['twists'] as String?;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('challenge_attempts')
                    .where('challengeId', isEqualTo: challengeId)
                    .snapshots(),
                builder: (context, attemptsSnap) {
                  final attempts = attemptsSnap.data?.docs ?? [];
                  final views = q['views'] ?? 0;
                  final submitted = attempts.length;
                  final correctCount = attempts.where((doc) => doc['isCorrect'] == true).length;
                  final accuracy = submitted > 0 ? ((correctCount / submitted) * 100).roundToDouble() : 0.0;

                  String commonWrongStr = 'None';
                  if (submitted > 0 && correctCount < submitted) {
                    final wrongOptionsMap = <int, int>{};
                    for (var doc in attempts) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['isCorrect'] != true) {
                        final sel = data['selectedOption'] as int?;
                        if (sel != null) {
                          wrongOptionsMap[sel] = (wrongOptionsMap[sel] ?? 0) + 1;
                        }
                      }
                    }
                    if (wrongOptionsMap.isNotEmpty) {
                      final sortedWrong = wrongOptionsMap.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      final mostCommonSel = sortedWrong.first.key;
                      final pct = ((sortedWrong.first.value / submitted) * 100).round();
                      final options = List<String>.from(q['options'] ?? []);
                      final optionLabel = mostCommonSel >= 0 && mostCommonSel < options.length
                          ? options[mostCommonSel]
                          : 'Option ${String.fromCharCode(65 + mostCommonSel)}';
                      commonWrongStr = '$optionLabel - $pct% of attempts';
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question #${index + 1} (${q["type"] ?? "MCQ"})',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              Text(
                                q['subject'] ?? 'General',
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            questionText,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          const Text('Live Metrics', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetricItem('Views', views.toString()),
                              _buildMetricItem('Attempts', submitted.toString()),
                              _buildMetricItem('Accuracy', '$accuracy%'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Common Mistake: $commonWrongStr',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Hints Configured', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () => _addHint(challengeId, hints),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Hint'),
                              ),
                            ],
                          ),
                          if (hints.isEmpty)
                            const Text('No hints configured.', style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic))
                          else
                            ...List.generate(
                              hints.length,
                              (hIdx) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  'Hint ${hIdx + 1}: ${hints[hIdx]}',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Active Twist', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () => _addTwist(challengeId, twistText),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Change Twist'),
                              ),
                            ],
                          ),
                          Text(
                            twistText != null && twistText.trim().isNotEmpty
                                ? twistText
                                : 'No twist published.',
                            style: TextStyle(
                              fontSize: 13,
                              color: twistText != null && twistText.trim().isNotEmpty ? Colors.black87 : Colors.grey,
                              fontStyle: twistText != null && twistText.trim().isNotEmpty ? FontStyle.normal : FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
