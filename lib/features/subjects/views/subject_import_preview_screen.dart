import 'package:flutter/material.dart';
import '../../../core/services/excel_preview_models.dart';
import '../../../core/theme/app_theme.dart';

class SubjectImportPreviewScreen extends StatefulWidget {
  final SubjectImportPreview preview;
  final Future<int> Function(List<SubjectImportRow>) onConfirm;

  const SubjectImportPreviewScreen({
    super.key,
    required this.preview,
    required this.onConfirm,
  });

  @override
  State<SubjectImportPreviewScreen> createState() =>
      _SubjectImportPreviewScreenState();
}

class _SubjectImportPreviewScreenState
    extends State<SubjectImportPreviewScreen> {
  late List<SubjectImportRow> _rows;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _rows = List.from(widget.preview.rows);
  }

  void _toggleRow(int index) {
    setState(() {
      _rows[index].shouldImport = !_rows[index].shouldImport;
    });
  }

  void _editRow(int index) {
    final controller = TextEditingController(text: _rows[index].name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('កែប្រែមុខវិជ្ជា'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'ឈ្មោះមុខវិជ្ជា'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('បោះបង់'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _rows[index].name = controller.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('រក្សាទុក'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final selectedRows = _rows.where((r) => r.shouldImport).toList();
      if (selectedRows.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('សូមជ្រើសរើសយ៉ាងហោចណាស់មួយធាតុ')),
        );
        return;
      }

      final count = await widget.onConfirm(selectedRows);

      if (!mounted) return;
      Navigator.pop(context, count);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('កំហុស៖ $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _rows.where((r) => r.shouldImport).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Import មុខវិជ្ជា'),
        actions: [
          TextButton.icon(
            onPressed: _isImporting ? null : _confirmImport,
            icon: _isImporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text('Import ($selectedCount)'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.preview.existingNames.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'មុខវិជ្ជាដែលមានរួចហើយនឹងត្រូវបានរំលងដោយស្វ័យប្រវត្តិ',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('គ្មានទិន្នន័យនៅក្នុងឯកសារ'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      final existsAlready = widget.preview.existingNames
                          .contains(row.name.trim().toLowerCase());

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: AppSizes.paddingSm,
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: row.shouldImport && !existsAlready,
                            onChanged: existsAlready
                                ? null
                                : (val) => _toggleRow(index),
                          ),
                          title: Text(
                            row.name,
                            style: TextStyle(
                              decoration: existsAlready
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: existsAlready
                                  ? Colors.grey
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: existsAlready
                              ? const Text(
                                  'មានរួចហើយ',
                                  style: TextStyle(color: Colors.orange),
                                )
                              : null,
                          trailing: existsAlready
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _editRow(index),
                                ),
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
