import 'package:flutter/material.dart';

// Predefined Khmer subjects
const List<String> _khmerSubjects = [
  'ភាសាខ្មែរ',
  'សីលធម៏័-ពលរដ្ធវិជ្ជា',
  'ប្រវត្តិវិទ្យា',
  'ភូមិវិទ្យា',
  'គណិតវិទ្យា',
  'រូបវិទ្យា',
  'គីមីវិទ្យា',
  'ជីវិទ្យា',
  'ផែនដីវិទ្យា',
  'ភាសាបរទេស',
  'បច្ចេកវិទ្យា',
  'គេហវិទ្យា',
  'អប់រំសិល្បៈ',
  'អប់រំកាយ កីឡា',
];

class AddClassDialog extends StatefulWidget {
  final void Function(
    String name,
    String year,
    bool isAdviser,
    List<String> subjects,
  )
  onSubmit;

  const AddClassDialog({super.key, required this.onSubmit});

  /// Convenience method to show the dialog.
  static void show(
    BuildContext context,
    void Function(
      String name,
      String year,
      bool isAdviser,
      List<String> subjects,
    )
    onSubmit,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddClassDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<AddClassDialog> {
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isAdviser = false;
  late Map<String, bool> _selectedSubjects;

  @override
  void initState() {
    super.initState();
    // Initialize all subjects as unselected
    _selectedSubjects = {for (var subject in _khmerSubjects) subject: false};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _selectSingleSubject(String subject) {
    setState(() {
      // Only allow one subject selected at a time
      _selectedSubjects.updateAll((key, value) => false);
      _selectedSubjects[subject] = !_selectedSubjects[subject]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedSubjects.values.where((v) => v).length;

    return AlertDialog(
      title: const Text(
        'បង្កើតថ្នាក់ថ្មី',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Info Section
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ព័ត៌មាននៃថ្នាក់',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'ឈ្មោះថ្នាក់',
                      hintText: 'ឧ. ថ្នាក់ទី ៦-ក',
                      prefixIcon: const Icon(Icons.class_),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _yearController,
                    decoration: InputDecoration(
                      labelText: 'ឆ្នាំសិក្សា',
                      hintText: '២០២៤-២០២៥',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Role Section
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(12),
              child: CheckboxListTile(
                title: const Text(
                  'ខ្ញុំជាគ្រូបន្ទុកថ្នាក់នេះ (Adviser)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  _isAdviser
                      ? 'អ្នកនឹងមានសិទ្ធិក្នុងការគ្រប់គ្រងថ្នាក់ និងមើលមុខវិជ្ជាទាំងអស់'
                      : 'អ្នកនឹងបង្រៀនមុខវិជ្ជាដែលបានជ្រើសរើស',
                  style: const TextStyle(fontSize: 12),
                ),
                value: _isAdviser,
                onChanged: (val) {
                  setState(() {
                    _isAdviser = val ?? false;
                  });
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            const SizedBox(height: 20),

            // Subjects Section
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ជ្រើសរើសមុខវិជ្ជារបស់អ្នក',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'រើសមុខវិជ្ជា ១ដែលអ្នកបង្រៀន',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$selectedCount/1',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_khmerSubjects.length, (index) {
                      final subject = _khmerSubjects[index];
                      final isSelected = _selectedSubjects[subject] ?? false;
                      final canSelect =
                          isSelected ||
                          !_selectedSubjects.values.contains(true);

                      return GestureDetector(
                        onTap: canSelect
                            ? () => _selectSingleSubject(subject)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              if (isSelected) const SizedBox(width: 4),
                              Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('បោះបង់'),
        ),
        FilledButton.icon(
          onPressed: () {
            final name = _nameController.text.trim();
            final year = _yearController.text.trim();
            final selectedSubjects = _selectedSubjects.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList();

            if (name.isEmpty || year.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('សូមបំពេញឈ្មោះ និងឆ្នាំសិក្សា')),
              );
              return;
            }

            if (selectedSubjects.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('សូមជ្រើសរើសមុខវិជ្ជាដែលអ្នកបង្រៀន'),
                ),
              );
              return;
            }

            widget.onSubmit(name, year, _isAdviser, selectedSubjects);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.add),
          label: const Text('បង្កើត'),
        ),
      ],
    );
  }
}
