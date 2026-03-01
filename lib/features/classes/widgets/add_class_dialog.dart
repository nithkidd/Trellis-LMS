import 'package:flutter/material.dart';

class AddClassDialog extends StatefulWidget {
  final void Function(String name, String year) onSubmit;

  const AddClassDialog({Key? key, required this.onSubmit}) : super(key: key);

  /// Convenience method to show the dialog.
  static void show(
    BuildContext context,
    void Function(String name, String year) onSubmit,
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

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('បន្ថែមថ្នាក់'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'ឈ្មោះថ្នាក់'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(
              labelText: 'ឆ្នាំសិក្សា (ឧ. 2024-2025)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('បោះបង់'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final year = _yearController.text.trim();
            if (name.isNotEmpty && year.isNotEmpty) {
              widget.onSubmit(name, year);
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('សូមបំពេញគ្រប់វាលទាំងអស់')),
              );
            }
          },
          child: const Text('បន្ថែម'),
        ),
      ],
    );
  }
}
