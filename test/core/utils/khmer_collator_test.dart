import 'package:flutter_test/flutter_test.dart';
import 'package:trellis/core/utils/khmer_collator.dart';

void main() {
  group('KhmerCollator Tests', () {
    test('should sort Khmer consonants in correct order', () {
      final names = [
        'រដ្ឋ',
        'កក់',
        'គុក',
        'ញុំ',
        'ជប់',
        'បាន',
        'មក',
        'យក',
        'សាលា',
        'ហាង',
        'អាន',
      ];
      final sorted = KhmerCollator.sortStrings(names);

      // Should start with ក, then ជ, ញ, រ, ប, ម, យ, ស, ហ, អ according to Khmer alphabet
      expect(sorted[0], 'កក់');
      expect(sorted[1], 'គុក');
      expect(sorted[2], 'ជប់');
      expect(sorted[3], 'ញុំ');
    });

    test('should handle mixed Khmer and English text', () {
      final names = ['ABC', 'ក្រុម', 'Group', 'បង'];
      final sorted = KhmerCollator.sortStrings(names);

      // Khmer characters should come first (lower indices)
      expect(sorted.indexOf('ក្រុម') < sorted.indexOf('ABC'), true);
      expect(sorted.indexOf('បង') < sorted.indexOf('Group'), true);
    });

    test('should sort empty strings', () {
      final names = ['', 'ក', 'គ'];
      final sorted = KhmerCollator.sortStrings(names);

      expect(sorted[0], '');
      expect(sorted[1], 'ក');
      expect(sorted[2], 'គ');
    });

    test('should sort students by Khmer names', () {
      final students = [
        {'id': 1, 'name': 'សុខា'},
        {'id': 2, 'name': 'កញ្ញា'},
        {'id': 3, 'name': 'រដ្ឋា'},
        {'id': 4, 'name': 'បញ្ញា'},
      ];

      students.sort(
        (a, b) =>
            KhmerCollator.compare(a['name'] as String, b['name'] as String),
      );

      // Should be sorted as: កញ្ញា, បញ្ញា, រដ្ឋា, សុខា
      expect(students[0]['name'], 'កញ្ញា');
      expect(students[1]['name'], 'បញ្ញា');
      expect(students[2]['name'], 'រដ្ឋា');
      expect(students[3]['name'], 'សុខា');
    });

    test('should handle Khmer numerals', () {
      final items = ['៣', '១', '២', '០'];
      final sorted = KhmerCollator.sortStrings(items);

      expect(sorted, ['០', '១', '២', '៣']);
    });

    test('should preserve original list when using sortBy', () {
      final students = [
        {'name': 'យុវា'},
        {'name': 'កញ្ញា'},
        {'name': 'សុខា'},
      ];

      final original = students.map((s) => s['name']).toList();
      KhmerCollator.sortBy(students, (s) => s['name'] as String);

      // List should be sorted by Khmer alphabet: ក, យ, ស
      expect(students[0]['name'], 'កញ្ញា');
      expect(students[1]['name'], 'យុវា');
      expect(students[2]['name'], 'សុខា');

      // Original variable should reference the same modified list
      expect(students[0]['name'] != original[0], true);
    });

    test('should compare identical strings as equal', () {
      final result = KhmerCollator.compare('កក់', 'កក់');
      expect(result, 0);
    });

    test('should sort dependent vowels correctly', () {
      // Names with different dependent vowels
      final names = ['កា', 'កិ', 'កី', 'កុ', 'កូ'];
      final sorted = KhmerCollator.sortStrings(names);

      // All should start with ក, then sort by vowel order
      expect(sorted[0], 'កា');
      expect(sorted[1], 'កិ');
      expect(sorted[2], 'កី');
    });

    test('should handle long student names', () {
      final names = ['ហ៊ុន សេនវិបុល', 'កែវ សុផល្លា', 'លី មករា'];
      final sorted = KhmerCollator.sortStrings(names);

      // Khmer alphabet order: ..., ល, វ, ស, ហ, ...
      expect(sorted[0], 'កែវ សុផល្លា'); // ក comes first
      expect(sorted[1], 'លី មករា'); // ល comes after ក
      expect(sorted[2], 'ហ៊ុន សេនវិបុល'); // ហ comes after ល
    });
  });
}
