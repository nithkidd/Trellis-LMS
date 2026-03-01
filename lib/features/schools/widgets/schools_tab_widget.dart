import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/school_provider.dart';
import 'school_list_tile_widget.dart';
import '../../../core/theme/app_theme.dart';

class SchoolsTabWidget extends ConsumerStatefulWidget {
  const SchoolsTabWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<SchoolsTabWidget> createState() => _SchoolsTabWidgetState();
}

class _SchoolsTabWidgetState extends ConsumerState<SchoolsTabWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isEditMode = false;
  final Set<int> _selectedSchoolIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedSchoolIds.clear();
      }
    });
  }

  void _deleteSelectedSchools() {
    if (_selectedSchoolIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('លុបសាលាដែលបានជ្រើស?'),
        content: Text(
          'លុបសាលាចំនួន ${_selectedSchoolIds.length} មែនទេ? វានឹងលុបថ្នាក់ សិស្ស និងពិន្ទុទាំងអស់នៅក្នុងសាលាទាំងនោះផងដែរ។',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              for (final id in _selectedSchoolIds) {
                ref.read(schoolNotifierProvider.notifier).deleteSchool(id);
              }
              Navigator.pop(ctx);
              setState(() {
                _selectedSchoolIds.clear();
                _isEditMode = false;
              });
            },
            child: const Text('លុប'),
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll(List<int?> allSchoolIds) {
    setState(() {
      if (_selectedSchoolIds.length == allSchoolIds.length) {
        // If all selected, deselect all
        _selectedSchoolIds.clear();
      } else {
        // Otherwise, select all
        _selectedSchoolIds.clear();
        for (final id in allSchoolIds) {
          if (id != null) _selectedSchoolIds.add(id);
        }
      }
    });
  }

  void _showAddSchoolDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('បន្ថែមសាលា'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'ឈ្មោះសាលា'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('បោះបង់'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(schoolNotifierProvider.notifier).addSchool(name);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('សូមបញ្ចូលឈ្មោះសាលា')),
                  );
                }
              },
              child: const Text('បន្ថែម'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolsState = ref.watch(schoolNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search Bar and Edit Button Row
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ស្វែងរកសាលា...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMd,
                        vertical: AppSizes.paddingSm,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSm),
                IconButton(
                  icon: Icon(
                    _isEditMode ? Icons.done : Icons.edit_outlined,
                    color: _isEditMode
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _isEditMode
                        ? Theme.of(context).colorScheme.primaryContainer
                        : AppColors.background,
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                  ),
                  onPressed: _toggleEditMode,
                  tooltip: _isEditMode ? 'រួចរាល់' : 'កែប្រែ',
                ),
              ],
            ),
          ),

          // Add Button or Delete Selected Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
            child: SizedBox(
              width: double.infinity,
              child: _isEditMode && _selectedSchoolIds.isNotEmpty
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.paddingMd,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                      ),
                      onPressed: _deleteSelectedSchools,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: AppSizes.iconLg,
                      ),
                      label: Text(
                        'លុបដែលបានជ្រើស ${_selectedSchoolIds.length}',
                        style: AppTextStyles.button,
                      ),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.paddingMd,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                      ),
                      onPressed: _isEditMode
                          ? null
                          : () => _showAddSchoolDialog(context),
                      icon: const Icon(Icons.add, size: AppSizes.iconLg),
                      label: const Text('បន្ថែម', style: AppTextStyles.button),
                    ),
            ),
          ),

          const SizedBox(height: AppSizes.paddingMd),

          // Select All option in edit mode
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMd,
              ),
              child: schoolsState.maybeWhen(
                data: (schools) {
                  final filteredSchools = _searchQuery.isEmpty
                      ? schools
                      : schools.where((school) {
                          return school.name.toLowerCase().contains(
                            _searchQuery,
                          );
                        }).toList();

                  if (filteredSchools.isEmpty) return const SizedBox.shrink();

                  final allIds = filteredSchools.map((s) => s.id).toList();
                  final allSelected =
                      _selectedSchoolIds.length == filteredSchools.length;

                  return Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _toggleSelectAll(allIds),
                        icon: Icon(
                          allSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                        ),
                        label: Text(
                          allSelected ? 'ដកជម្រើសទាំងអស់' : 'ជ្រើសទាំងអស់',
                        ),
                      ),
                      const Spacer(),
                      if (_selectedSchoolIds.isNotEmpty)
                        Text(
                          'បានជ្រើស ${_selectedSchoolIds.length}',
                          style: AppTextStyles.caption,
                        ),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),

          // Schools List
          Expanded(
            child: schoolsState.when(
              data: (schools) {
                // Filter schools based on search query
                final filteredSchools = _searchQuery.isEmpty
                    ? schools
                    : schools.where((school) {
                        return school.name.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (filteredSchools.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLg),
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'មិនទាន់មានសាលា។\nចុចបន្ថែមខាងលើដើម្បីបង្កើត។'
                            : 'រកមិនឃើញសាលាដែលត្រូវនឹង "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                }

                // Show ReorderableListView only in edit mode, otherwise regular ListView
                if (_isEditMode) {
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMd,
                      vertical: AppSizes.paddingSm,
                    ),
                    itemCount: filteredSchools.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(schoolNotifierProvider.notifier)
                          .reorderSchools(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final school = filteredSchools[index];
                      final isSelected = _selectedSchoolIds.contains(school.id);

                      return Padding(
                        key: ValueKey(school.id),
                        padding: const EdgeInsets.only(
                          bottom: AppSizes.paddingSm,
                        ),
                        child: Card(
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true && school.id != null) {
                                        _selectedSchoolIds.add(school.id!);
                                      } else {
                                        _selectedSchoolIds.remove(school.id);
                                      }
                                    });
                                  },
                                ),
                                Icon(
                                  Icons.drag_handle,
                                  color: AppColors.textSecondary.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              school.name,
                              style: AppTextStyles.subheading,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                // Normal mode - regular ListView
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMd,
                    vertical: AppSizes.paddingSm,
                  ),
                  itemCount: filteredSchools.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.paddingSm),
                  itemBuilder: (context, index) {
                    final school = filteredSchools[index];
                    return SchoolListTileWidget(
                      school: school,
                      onDelete: () {
                        if (school.id != null) {
                          ref
                              .read(schoolNotifierProvider.notifier)
                              .deleteSchool(school.id!);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'កំហុស៖ $error',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
