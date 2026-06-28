import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../subscription/plan_selection_screen.dart';
import 'video_page.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  String? _selectedCourseName;
  String? _userPlan;
  bool _isLoading = true;
  String? _errorMessage;

  String? _userClass;
  List<String> _userSubjects = [];
  bool _isFiltered = false;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String? userClass;
      List<String> userSubjects = [];
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          _userPlan = userDoc.data()?['plan'];
          userClass = userDoc.data()?['className'];
          if (userDoc.data()?['subjects'] != null) {
            userSubjects = List<String>.from(userDoc.data()?['subjects']);
          }
        }
      }

      // Fetch custom courses
      final coursesSnapshot = await FirebaseFirestore.instance.collection('courses').get();
      var coursesList = coursesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'title': doc.data()['title'] ?? 'Untitled Course',
        'subject': doc.data()['subject'] ?? '',
        'className': doc.data()['className'] ?? '',
      }).toList();

      bool isFiltered = false;
      if ((userClass != null && userClass.isNotEmpty) || userSubjects.isNotEmpty) {
        final filtered = coursesList.where((course) {
          final matchesClass = userClass == null || userClass.isEmpty || course['className'] == userClass;
          final matchesSubject = userSubjects.isEmpty || userSubjects.contains(course['subject']);
          return matchesClass && matchesSubject;
        }).toList();

        if (filtered.isNotEmpty) {
          coursesList = filtered;
          isFiltered = true;
        }
      }

      final callable = FirebaseFunctions.instance.httpsCallable('getSubjectsAndMaterials');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);

      if (data['success'] == true) {
        final List rawList = data['materials'] as List;
        final materialsList = rawList
            .map((item) => Map<String, dynamic>.from(item as Map))
            // Only show syllabus based content
            .where((item) => item['isSyllabusBased'] == true)
            .toList();

        if (mounted) {
          setState(() {
            _materials = materialsList;
            _courses = coursesList;
            _userClass = userClass;
            _userSubjects = userSubjects;
            _isFiltered = isFiltered;
            if (_courses.isNotEmpty) {
              _selectedCourseId = _courses.first['id'];
              _selectedCourseName = _courses.first['title'];
            } else {
              _selectedCourseId = null;
              _selectedCourseName = null;
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load syllabus content';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching materials: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Content', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This lecture note/video is premium. Please select a subscription plan to unlock full access to all lectures and documents.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
              );
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchMaterials();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredVideos = _materials.where((m) =>
        m['courseId'] == _selectedCourseId && m['videoUrl'] != null).toList();
    final filteredPdfs = _materials.where((m) =>
        m['courseId'] == _selectedCourseId && m['pdfUrl'] != null).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Courses & Syllabus', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          if (_userClass != null && _userClass!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    _isFiltered
                        ? 'Preferences: $_userClass • ${_userSubjects.join(", ")}'
                        : 'No match for $_userClass • ${_userSubjects.join(", ")} (Showing all courses)',
                    style: TextStyle(
                      fontSize: 12, 
                      color: Theme.of(context).colorScheme.primary, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildCourseList(context),
          const SizedBox(height: 32),
          Text(
            _selectedCourseName != null ? '$_selectedCourseName: Lectures' : 'Lectures',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (filteredVideos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No video lectures for this course yet.', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredVideos.length,
              itemBuilder: (context, index) {
                final video = filteredVideos[index];
                return _buildLectureCard(
                  context: context,
                  video: video,
                  title: video['title'] ?? 'Untitled Video',
                  isFree: video['isFree'] ?? true,
                  price: video['price'] ?? 0,
                  description: video['description'] ?? '',
                );
              },
            ),
          const SizedBox(height: 32),
          Text('Study Notes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (filteredPdfs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No study guides or notes for this course yet.', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredPdfs.length,
              itemBuilder: (context, index) {
                final pdf = filteredPdfs[index];
                return _buildNotesCard(
                  context: context,
                  pdf: pdf,
                  title: pdf['title'] ?? 'Untitled Document',
                  subtitle: pdf['pdfFileName'] ?? 'Document Note',
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCourseList(BuildContext context) {
    if (_courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No courses created by teachers yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          final isSelected = _selectedCourseId == course['id'];
          final color = isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCourseId = course['id'];
                _selectedCourseName = course['title'];
              });
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    radius: 20,
                    child: Icon(Icons.school_outlined, color: color),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      course['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? color : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${course['className']} - ${course['subject']}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLectureCard({
    required BuildContext context,
    required Map<String, dynamic> video,
    required String title,
    required bool isFree,
    required dynamic price,
    required String description,
  }) {
    final hasPlan = _userPlan != null && _userPlan!.isNotEmpty;
    final isUnlocked = isFree || hasPlan;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUnlocked
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.amber.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUnlocked ? Icons.play_arrow : Icons.lock,
            color: isUnlocked ? Theme.of(context).colorScheme.primary : Colors.amber,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            if (!isFree && !hasPlan)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$$price',
                  style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          if (!isUnlocked) {
            _showSubscriptionDialog(context);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPage(
                docId: video['id'] ?? '',
                topicTitle: title,
                chapterTitle: _selectedCourseName ?? '',
                videoUrl: video['videoUrl'] ?? '',
                pdfUrl: video['pdfUrl'],
                pdfFileName: video['pdfFileName'],
                description: description,
                isFree: isFree,
                price: price,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesCard({
    required BuildContext context,
    required Map<String, dynamic> pdf,
    required String title,
    required String subtitle,
  }) {
    final isFree = pdf['isFree'] ?? true;
    final hasPlan = _userPlan != null && _userPlan!.isNotEmpty;
    final isUnlocked = isFree || hasPlan;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.picture_as_pdf, color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: IconButton(
          icon: Icon(isUnlocked ? Icons.download : Icons.lock),
          color: isUnlocked ? Theme.of(context).colorScheme.primary : Colors.amber,
          onPressed: () async {
            if (!isUnlocked) {
              _showSubscriptionDialog(context);
              return;
            }
            final url = pdf['pdfUrl'] as String?;
            if (url != null && url.isNotEmpty) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No PDF file associated with this course.')),
              );
            }
          },
        ),
      ),
    );
  }
}

