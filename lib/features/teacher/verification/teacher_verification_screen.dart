import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../dashboard/teacher_dashboard_screen.dart';

// ---------------------------------------------------------------------------
// Enums / constants
// ---------------------------------------------------------------------------

const _degrees = [
  "Bachelor's (B.A / B.Sc / B.Tech / B.E)",
  "Master's (M.A / M.Sc / M.Tech / M.E)",
  'Ph.D.',
  'Diploma',
  'Other',
];

const _subjects = ['Physics', 'Chemistry', 'Mathematics', 'Biology', 'Others'];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TeacherVerificationScreen extends StatefulWidget {
  const TeacherVerificationScreen({super.key});

  @override
  State<TeacherVerificationScreen> createState() =>
      _TeacherVerificationScreenState();
}

class _TeacherVerificationScreenState
    extends State<TeacherVerificationScreen> {
  // ── Step tracking ──────────────────────────────────────────────────────────
  int _step = 0; // 0 = qualifications, 1 = demo video, 2 = submitted

  // ── Step 1 state ───────────────────────────────────────────────────────────
  String? _selectedDegree;
  String? _selectedSubject;
  final _otherSubjectController = TextEditingController();
  bool _showOtherSubject = false;

  PlatformFile? _degreeFile;
  double? _degreeUploadProgress; // null = not uploading, 0–1 = progress
  String? _degreeDownloadUrl;

  // ── Step 2 state ───────────────────────────────────────────────────────────
  PlatformFile? _videoFile;
  VideoPlayerController? _videoController;
  double? _videoUploadProgress;
  String? _videoDownloadUrl;

  bool _isSubmitting = false;

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _effectiveSubject =>
      _selectedSubject == 'Others' ? _otherSubjectController.text.trim() : (_selectedSubject ?? '');

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colors => _theme.colorScheme;

  // ── File picking & upload ──────────────────────────────────────────────────

  Future<void> _pickDegreeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _degreeFile = result.files.first;
      _degreeDownloadUrl = null;
      _degreeUploadProgress = null;
    });
    await _uploadDegreeFile();
  }

  Future<void> _uploadDegreeFile() async {
    final file = _degreeFile;
    if (file == null || file.path == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _degreeUploadProgress = 0.0);

    try {
      final ref = FirebaseStorage.instance
          .ref('teacher_verifications/$uid/degree/${file.name}');
      final task = ref.putFile(File(file.path!));

      task.snapshotEvents.listen((snap) {
        if (!mounted) return;
        if (snap.totalBytes == 0) return;
        final progress = snap.bytesTransferred / snap.totalBytes;
        setState(() => _degreeUploadProgress = progress.clamp(0.0, 1.0));
      });

      await task;
      final url = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() {
        _degreeDownloadUrl = url;
        _degreeUploadProgress = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _degreeUploadProgress = null);
      _showError('Degree upload failed: $e');
    }
  }

  Future<void> _pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;

    // Dispose previous controller
    await _videoController?.dispose();
    _videoController = null;

    setState(() {
      _videoFile = picked;
      _videoDownloadUrl = null;
      _videoUploadProgress = null;
    });

    // Init local preview
    if (picked.path != null) {
      final ctrl = VideoPlayerController.file(File(picked.path!));
      await ctrl.initialize();
      if (!mounted) return;
      setState(() => _videoController = ctrl);
    }

    await _uploadVideoFile();
  }

  Future<void> _uploadVideoFile() async {
    final file = _videoFile;
    if (file == null || file.path == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _videoUploadProgress = 0.0);

    try {
      final ref = FirebaseStorage.instance
          .ref('teacher_verifications/$uid/demo_video/${file.name}');
      final task = ref.putFile(File(file.path!));

      task.snapshotEvents.listen((snap) {
        if (!mounted) return;
        if (snap.totalBytes == 0) return;
        final progress = snap.bytesTransferred / snap.totalBytes;
        setState(() => _videoUploadProgress = progress.clamp(0.0, 1.0));
      });

      await task;
      final url = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() {
        _videoDownloadUrl = url;
        _videoUploadProgress = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _videoUploadProgress = null);
      _showError('Video upload failed: $e');
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _nextFromStep0() {
    if (_selectedDegree == null) {
      _showError('Please select your highest degree.');
      return;
    }
    if (_selectedSubject == null) {
      _showError('Please select the subject you teach.');
      return;
    }
    if (_selectedSubject == 'Others' && _otherSubjectController.text.trim().isEmpty) {
      _showError('Please specify your subject.');
      return;
    }
    if (_degreeFile == null) {
      _showError('Please upload your degree certificate.');
      return;
    }
    if (_degreeUploadProgress != null) {
      _showError('Please wait for the degree upload to finish.');
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _submitApplication() async {
    if (_videoFile == null) {
      _showError('Please upload your demo teaching video.');
      return;
    }
    if (_videoUploadProgress != null) {
      _showError('Please wait for the video upload to finish.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({
          'verificationStatus': 'pending',
          'degree': _selectedDegree,
          'subject': _effectiveSubject,
          'degreeFileUrl': _degreeDownloadUrl,
          'demoVideoUrl': _videoDownloadUrl,
          'submittedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      if (!mounted) return;
      setState(() => _step = 2);
    } catch (e) {
      if (!mounted) return;
      _showError('Submission failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _otherSubjectController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.surface,
      appBar: AppBar(
        title: const Text('Teacher Verification'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        // Hide default back button when on submitted screen
        automaticallyImplyLeading: _step < 2,
      ),
      body: Column(
        children: [
          if (_step < 2) _buildStepIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _buildStep(_step),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ─────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    final labels = ['Qualifications', 'Demo Video'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // connector line
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < _step
                    ? _colors.primary
                    : _colors.outlineVariant,
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < _step;
          final active = idx == _step;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? _colors.primary : _colors.surfaceContainerHighest,
                  border: active
                      ? Border.all(color: _colors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: active ? Colors.white : _colors.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[idx],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? _colors.primary : _colors.onSurfaceVariant,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Step router ────────────────────────────────────────────────────────────

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildStep0(key: const ValueKey(0));
      case 1:
        return _buildStep1(key: const ValueKey(1));
      default:
        return _buildSubmittedScreen(key: const ValueKey(2));
    }
  }

  // ── Step 0 – Qualifications ────────────────────────────────────────────────

  Widget _buildStep0({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Step 1: Your Qualifications',
              style: _theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Tell us about your academic background and upload your degree certificate.',
            style: _theme.textTheme.bodyMedium
                ?.copyWith(color: _colors.onSurfaceVariant),
          ),
          const SizedBox(height: 28),

          // ── Highest degree dropdown
          _SectionLabel(label: 'Highest Degree'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: _inputDecoration('Select your degree'),
            initialValue: _selectedDegree,
            isExpanded: true,
            items: _degrees
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (val) => setState(() => _selectedDegree = val),
          ),
          const SizedBox(height: 20),

          // ── Subject dropdown
          _SectionLabel(label: 'Subject You Teach'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: _inputDecoration('Select subject'),
            initialValue: _selectedSubject,
            isExpanded: true,
            items: _subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedSubject = val;
                _showOtherSubject = val == 'Others';
              });
            },
          ),
          if (_showOtherSubject) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otherSubjectController,
              decoration: _inputDecoration('Enter your subject'),
              textCapitalization: TextCapitalization.words,
            ),
          ],
          const SizedBox(height: 28),

          // ── Degree certificate upload
          _SectionLabel(label: 'Degree Certificate'),
          const SizedBox(height: 6),
          Text(
            'Accepted formats: PDF, JPG, PNG',
            style: _theme.textTheme.bodySmall
                ?.copyWith(color: _colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          _UploadCard(
            icon: _degreeDownloadUrl != null
                ? Icons.task_alt_rounded
                : Icons.upload_file_rounded,
            label: _degreeFile == null
                ? 'Tap to select degree certificate'
                : _degreeFile!.name,
            sublabel: _degreeDownloadUrl != null ? 'Uploaded successfully' : null,
            progress: _degreeUploadProgress,
            isSuccess: _degreeDownloadUrl != null,
            onTap: _degreeUploadProgress == null ? _pickDegreeFile : null,
          ),
          const SizedBox(height: 36),

          // ── Navigation buttons
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _nextFromStep0,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Next Step'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Step 1 – Demo Video ────────────────────────────────────────────────────

  Widget _buildStep1({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Step 2: Demo Teaching Video',
              style: _theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Record a 2–5 minute demo lesson. This helps our reviewers evaluate your teaching skills.',
            style: _theme.textTheme.bodyMedium
                ?.copyWith(color: _colors.onSurfaceVariant),
          ),
          const SizedBox(height: 28),

          // ── Video picker card
          _UploadCard(
            icon: _videoDownloadUrl != null
                ? Icons.video_file_rounded
                : Icons.video_call_rounded,
            label: _videoFile == null
                ? 'Tap to select demo video'
                : _videoFile!.name,
            sublabel: _videoDownloadUrl != null ? 'Uploaded successfully' : null,
            progress: _videoUploadProgress,
            isSuccess: _videoDownloadUrl != null,
            onTap: _videoUploadProgress == null ? _pickVideoFile : null,
          ),

          // ── Local video preview
          if (_videoController != null &&
              _videoController!.value.isInitialized) ...[
            const SizedBox(height: 20),
            _SectionLabel(label: 'Preview'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_videoController!),
                    _VideoControls(controller: _videoController!),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 36),

          // ── Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: _colors.outline),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Submitting…' : 'Submit Application'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Step 2 – Submitted ─────────────────────────────────────────────────────

  Widget _buildSubmittedScreen({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pending_actions_rounded,
                size: 72, color: Colors.orange),
          ),
          const SizedBox(height: 32),
          Text(
            'Application Submitted!',
            textAlign: TextAlign.center,
            style: _theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Our verification team will review your qualifications and demo video. This usually takes 24–48 hours.',
            textAlign: TextAlign.center,
            style: _theme.textTheme.bodyMedium
                ?.copyWith(color: _colors.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will be notified by email once your account is approved.',
                    style: _theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set({'onboardingComplete': true}, SetOptions(merge: true));
              }
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const TeacherDashboardScreen()),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _colors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final double? progress; // null = idle, 0–1 = uploading
  final bool isSuccess;
  final VoidCallback? onTap;

  const _UploadCard({
    required this.icon,
    required this.label,
    this.sublabel,
    this.progress,
    required this.isSuccess,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUploading = progress != null;

    Color borderColor = colors.outline.withValues(alpha: 0.4);
    Color iconColor = colors.onSurfaceVariant;
    Color bg = colors.surfaceContainerLowest;

    if (isSuccess) {
      borderColor = Colors.green;
      iconColor = Colors.green;
      bg = Colors.green.withValues(alpha: 0.05);
    } else if (isUploading) {
      borderColor = colors.primary;
      iconColor = colors.primary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isUploading ? 2 : 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: iconColor),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSuccess ? Colors.green : colors.onSurface,
                fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 4),
              Text(
                sublabel!,
                style: TextStyle(
                    fontSize: 12,
                    color: isSuccess ? Colors.green : colors.onSurfaceVariant),
              ),
            ],
            if (isUploading) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                '${((progress ?? 0) * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Simple play/pause overlay for video preview
class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final isPlaying = ctrl.value.isPlaying;
    final position = ctrl.value.position;
    final duration = ctrl.value.duration;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white),
            onPressed: () {
              isPlaying ? ctrl.pause() : ctrl.play();
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              ctrl,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              colors: VideoProgressColors(
                playedColor: Theme.of(context).colorScheme.primary,
                bufferedColor: Colors.white38,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_fmt(position)} / ${_fmt(duration)}',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
