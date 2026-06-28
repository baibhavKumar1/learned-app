import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubject = 'All';
  String _selectedClass = 'All';
  List<Map<String, String>> _results = [];

  final List<Map<String, String>> _allItems = [
    {
      'title': 'Introduction to Derivatives',
      'type': 'Chapter',
      'subject': 'Maths',
      'class': '12th',
    },
    {
      'title': 'Newton\'s Laws of Motion',
      'type': 'Video',
      'subject': 'Physics',
      'class': '11th',
    },
    {
      'title': 'Organic Chemistry Basics',
      'type': 'Notes',
      'subject': 'Chemistry',
      'class': '12th',
    },
    {
      'title': 'Integration Formulas',
      'type': 'Notes',
      'subject': 'Maths',
      'class': '12th',
    },
    {
      'title': 'Electrostatics and Fields',
      'type': 'Chapter',
      'subject': 'Physics',
      'class': '12th',
    },
    {
      'title': 'Cell Structures',
      'type': 'Video',
      'subject': 'Biology',
      'class': '10th',
    },
  ];

  @override
  void initState() {
    super.initState();
    _results = List.from(_allItems);
  }

  void _runSearch(String query) {
    setState(() {
      _results = _allItems.where((item) {
        final matchesQuery = item['title']!.toLowerCase().contains(
          query.toLowerCase(),
        );
        final matchesSubject =
            _selectedSubject == 'All' || item['subject'] == _selectedSubject;
        final matchesClass =
            _selectedClass == 'All' || item['class'] == _selectedClass;
        return matchesQuery && matchesSubject && matchesClass;
      }).toList();
    });
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Filter Search',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Subject',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        ['All', 'Maths', 'Physics', 'Chemistry', 'Biology'].map(
                          (sub) {
                            final isSel = _selectedSubject == sub;
                            return ChoiceChip(
                              label: Text(sub),
                              selected: isSel,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedSubject = sub;
                                });
                                setState(() {
                                  _runSearch(_searchController.text);
                                });
                              },
                            );
                          },
                        ).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Class',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', '10th', '11th', '12th'].map((cls) {
                      final isSel = _selectedClass == cls;
                      return ChoiceChip(
                        label: Text(cls),
                        selected: isSel,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedClass = cls;
                          });
                          setState(() {
                            _runSearch(_searchController.text);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _runSearch,
                    decoration: InputDecoration(
                      hintText: 'Search chapters, notes, videos...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _openFilterPanel,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text('No results found. Try adjusting filters.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      IconData icon;
                      switch (item['type']) {
                        case 'Chapter':
                          icon = Icons.menu_book;
                          break;
                        case 'Video':
                          icon = Icons.play_circle_outline;
                          break;
                        default:
                          icon = Icons.description;
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              icon,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            item['title']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item['subject']} • ${item['class']} • ${item['type']}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening ${item['title']}'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
