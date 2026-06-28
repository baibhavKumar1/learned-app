import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'new_question_post_screen.dart';
import 'create_course_screen.dart';

class UploadContentScreen extends StatefulWidget {
  final int initialTabIndex;
  const UploadContentScreen({super.key, this.initialTabIndex = 0});

  @override
  State<UploadContentScreen> createState() => _UploadContentScreenState();
}

class _UploadContentScreenState extends State<UploadContentScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedClass = '12th';
  String _selectedSubject = 'Physics';
  bool _isFree = true;
  bool _isSyllabusBased = true;
  String? _selectedCourseId;
  List<Map<String, dynamic>> _myCourses = [];
  bool _isLoadingCourses = true;

  PlatformFile? _videoFile;
  PlatformFile? _pdfFile;

  double? _videoUploadProgress;
  double? _pdfUploadProgress;

  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('teacherId', isEqualTo: uid)
          .get();
      final courses = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc.data()['title'] ?? 'Untitled Course',
          'subject': doc.data()['subject'] ?? '',
          'className': doc.data()['className'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _myCourses = courses;
          if (courses.isNotEmpty) {
            _selectedCourseId = courses.first['id'];
            _selectedClass = courses.first['className'] ?? '12th';
            _selectedSubject = courses.first['subject'] ?? 'Physics';
          }
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      if (mounted) {
        setState(() {
          _isLoadingCourses = false;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _videoFile = result.files.first;
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pdfFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadFile(
    PlatformFile file,
    String folder,
    String docId,
    void Function(double) onProgress,
  ) async {
    if (file.path == null) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    try {
      final ref = FirebaseStorage.instance.ref(
        'course_materials/$docId/$folder/${file.name}',
      );
      final task = ref.putFile(File(file.path!));

      task.snapshotEvents.listen((snap) {
        if (!mounted) return;
        if (snap.totalBytes == 0) return;
        final progress = snap.bytesTransferred / snap.totalBytes;
        onProgress(progress.clamp(0.0, 1.0));
      });

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _publishContent() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      _showError('Please enter content title and description');
      return;
    }
    if (_videoFile == null && _pdfFile == null) {
      _showError('Please select at least one video or PDF to publish');
      return;
    }
    if (_isSyllabusBased && _selectedCourseId == null) {
      _showError('Please select or create a course first');
      return;
    }
    if (!_isFree && _priceController.text.trim().isEmpty) {
      _showError('Please enter a price for premium content');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isPublishing = true;
    });

    try {
      // 1. Create a document reference to get an ID before uploading
      final docRef = FirebaseFirestore.instance
          .collection('course_materials')
          .doc();
      final docId = docRef.id;

      String? videoUrl;
      String? pdfUrl;

      // 2. Upload Video if selected
      if (_videoFile != null) {
        videoUrl = await _uploadFile(_videoFile!, 'videos', docId, (progress) {
          setState(() => _videoUploadProgress = progress);
        });
        if (videoUrl == null) throw Exception('Failed to upload video');
      }

      // 3. Upload PDF if selected
      if (_pdfFile != null) {
        pdfUrl = await _uploadFile(_pdfFile!, 'pdfs', docId, (progress) {
          setState(() => _pdfUploadProgress = progress);
        });
        if (pdfUrl == null) throw Exception('Failed to upload PDF');
      }

      // 4. Save metadata to Firestore
      await docRef.set({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'className': _isSyllabusBased ? _selectedClass : 'General',
        'subject': _isSyllabusBased ? _selectedSubject : 'General',
        'isFree': _isFree,
        'price': _isFree
            ? 0
            : double.tryParse(_priceController.text.trim()) ?? 0,
        'videoUrl': videoUrl,
        'videoFileName': _videoFile?.name,
        'pdfUrl': pdfUrl,
        'pdfFileName': _pdfFile?.name,
        'teacherId': user.uid,
        'isSyllabusBased': _isSyllabusBased,
        'courseId': _isSyllabusBased ? _selectedCourseId : null,
        'createdAt': FieldValue.serverTimestamp(),
        // Initialize real analytics counters
        'views': 0,
        'likesCount': 0,
        'helpfulCount': 0,
        'commentsCount': 0,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content published successfully!')),
      );

      // Reset form
      setState(() {
        _titleController.clear();
        _descController.clear();
        _priceController.clear();
        _videoFile = null;
        _pdfFile = null;
        _videoUploadProgress = null;
        _pdfUploadProgress = null;
        _isFree = true;
        _isPublishing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _videoUploadProgress = null;
        _pdfUploadProgress = null;
      });
      _showError('Publish failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Content Material'),
              Tab(text: 'Feed Challenge'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMaterialForm(context),
                const NewQuestionPostScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            enabled: !_isPublishing,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            enabled: !_isPublishing,
          ),
          const SizedBox(height: 20),
          const Text(
            'Content Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Syllabus / Course')),
                  selected: _isSyllabusBased,
                  onSelected: _isPublishing
                      ? null
                      : (val) => setState(() {
                          _isSyllabusBased = true;
                        }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Extra / General Video')),
                  selected: !_isSyllabusBased,
                  onSelected: _isPublishing
                      ? null
                      : (val) => setState(() {
                          _isSyllabusBased = false;
                        }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isSyllabusBased) ...[
            if (_isLoadingCourses)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_myCourses.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'No courses found. You need to create a course first.',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateCourseScreen(),
                        ),
                      );
                      _fetchCourses();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo,
                    ),
                    child: const Text('Create a Course Now'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedCourseId,
                      items: _myCourses
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c['id'] as String,
                              child: Text(
                                '${c['title']} (${c['className']} - ${c['subject']})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isPublishing
                          ? null
                          : (val) {
                              if (val != null) {
                                final selectedCourse = _myCourses.firstWhere(
                                  (c) => c['id'] == val,
                                );
                                setState(() {
                                  _selectedCourseId = val;
                                  _selectedClass =
                                      selectedCourse['className'] ?? '12th';
                                  _selectedSubject =
                                      selectedCourse['subject'] ?? 'Physics';
                                });
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.indigo,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateCourseScreen(),
                        ),
                      );
                      _fetchCourses();
                    },
                  ),
                ],
              ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Select Files to Upload',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUploadCard(
                  icon: Icons.video_library,
                  label: _videoFile != null ? _videoFile!.name : 'Choose Video',
                  progress: _videoUploadProgress,
                  isSelected: _videoFile != null,
                  onTap: _isPublishing ? null : _pickVideo,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUploadCard(
                  icon: Icons.picture_as_pdf,
                  label: _pdfFile != null ? _pdfFile!.name : 'Choose PDF Note',
                  progress: _pdfUploadProgress,
                  isSelected: _pdfFile != null,
                  onTap: _isPublishing ? null : _pickPdf,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Pricing', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Free')),
                  selected: _isFree,
                  onSelected: _isPublishing
                      ? null
                      : (val) => setState(() => _isFree = true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Premium')),
                  selected: !_isFree,
                  onSelected: _isPublishing
                      ? null
                      : (val) => setState(() => _isFree = false),
                ),
              ),
            ],
          ),
          if (!_isFree) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              enabled: !_isPublishing,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isPublishing ? null : _publishContent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isPublishing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Publish Material',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required IconData icon,
    required String label,
    required double? progress,
    required bool isSelected,
    required VoidCallback? onTap,
    required MaterialColor color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? color.shade700 : Colors.black87,
                fontSize: 12,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                color: color,
                backgroundColor: color.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 10, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
