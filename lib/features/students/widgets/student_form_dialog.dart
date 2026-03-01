import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';

class StudentFormDialog extends StatefulWidget {
  final StudentModel? student; // null means adding new student
  final int classId;

  const StudentFormDialog({Key? key, this.student, required this.classId})
    : super(key: key);

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _remarksController;

  String? _sex;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _addressController = TextEditingController(
      text: widget.student?.address ?? '',
    );
    _remarksController = TextEditingController(
      text: widget.student?.remarks ?? '',
    );
    _sex = widget.student?.sex;

    if (widget.student?.dateOfBirth != null) {
      try {
        _dateOfBirth = DateTime.parse(widget.student!.dateOfBirth!);
      } catch (e) {
        _dateOfBirth = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final result = {
        'name': _nameController.text.trim(),
        'sex': _sex,
        'dateOfBirth': _dateOfBirth?.toIso8601String().split('T')[0],
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'remarks': _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      };

      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing ? 'កែប្រែព័ត៌មានសិស្ស' : 'បន្ថែមសិស្សថ្មី',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name field (required)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'ឈ្មោះពេញ *',
                      hintText: 'បញ្ចូលឈ្មោះពេញសិស្ស',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'សូមបញ្ចូលឈ្មោះសិស្ស';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sex dropdown
                  DropdownButtonFormField<String>(
                    value: _sex,
                    decoration: const InputDecoration(
                      labelText: 'ភេទ',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('ប្រុស (Male)')),
                      DropdownMenuItem(
                        value: 'F',
                        child: Text('ស្រី (Female)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sex = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date of birth picker
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'ថ្ងៃខែឆ្នាំកំណើត',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateOfBirth == null
                            ? 'ជ្រើសរើសថ្ងៃខែឆ្នាំកំណើត'
                            : DateFormat('dd/MM/yyyy').format(_dateOfBirth!),
                        style: TextStyle(
                          color: _dateOfBirth == null
                              ? Colors.grey
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address field
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'អាសយដ្ឋាន',
                      hintText: 'ភូមិ ឃុំ ស្រុក ខេត្ត',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Remarks field
                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'កំណត់សម្គាល់',
                      hintText: 'ព័ត៌មានបន្ថែម',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('បោះបង់'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _submit,
                        child: Text(isEditing ? 'រក្សាទុក' : 'បន្ថែម'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
