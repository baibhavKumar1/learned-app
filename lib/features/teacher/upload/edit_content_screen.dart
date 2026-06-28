import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditContentScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const EditContentScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<EditContentScreen> createState() => _EditContentScreenState();
}

class _EditContentScreenState extends State<EditContentScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  late String _selectedClass;
  late String _selectedSubject;
  late bool _isFree;
  late bool _isVisible;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData['title']);
    _descController = TextEditingController(
      text: widget.initialData['description'],
    );
    _priceController = TextEditingController(
      text: (widget.initialData['price'] ?? 0).toString(),
    );

    _selectedClass = widget.initialData['className'] ?? '12th';
    _selectedSubject = widget.initialData['subject'] ?? 'Physics';
    _isFree = widget.initialData['isFree'] ?? true;
    _isVisible = widget.initialData['isVisible'] ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and description')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('course_materials')
          .doc(widget.docId)
          .update({
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'className': _selectedClass,
            'subject': _selectedSubject,
            'isFree': _isFree,
            'price': _isFree
                ? 0
                : double.tryParse(_priceController.text.trim()) ?? 0,
            'isVisible': _isVisible,
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Content?'),
                  content: const Text(
                    'Are you sure you want to delete this content? This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // In a real app, you would also delete the files from Firebase Storage here.
                await FirebaseFirestore.instance
                    .collection('course_materials')
                    .doc(widget.docId)
                    .delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Content deleted')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text(
                'Visible to Students',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _isVisible
                    ? 'Students can see and access this content'
                    : 'This content is hidden from students',
              ),
              value: _isVisible,
              onChanged: _isSaving
                  ? null
                  : (val) => setState(() => _isVisible = val),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedClass,
                    items: ['10th', '11th', '12th']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (val) {
                            if (val != null)
                              setState(() => _selectedClass = val);
                          },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedSubject,
                    items: ['Physics', 'Chemistry', 'Mathematics', 'Biology']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (val) {
                            if (val != null)
                              setState(() => _selectedSubject = val);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Pricing',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Free')),
                    selected: _isFree,
                    onSelected: _isSaving
                        ? null
                        : (val) => setState(() => _isFree = true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Premium')),
                    selected: !_isFree,
                    onSelected: _isSaving
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
                enabled: !_isSaving,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
