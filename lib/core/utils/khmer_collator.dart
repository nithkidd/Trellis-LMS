/// Khmer alphabet collation utility
///
/// Provides proper Khmer alphabetical sorting following the traditional order
/// of Khmer consonants, vowels, and other characters.
class KhmerCollator {
  // Khmer consonants in alphabetical order (ក-អ)
  static const List<String> _consonants = [
    'ក',
    'ខ',
    'គ',
    'ឃ',
    'ង',
    'ច',
    'ឆ',
    'ជ',
    'ឈ',
    'ញ',
    'ដ',
    'ឋ',
    'ឌ',
    'ឍ',
    'ណ',
    'ត',
    'ថ',
    'ទ',
    'ធ',
    'ន',
    'ប',
    'ផ',
    'ព',
    'ភ',
    'ម',
    'យ',
    'រ',
    'ល',
    'វ',
    'ស',
    'ហ',
    'ឡ',
    'អ',
  ];

  // Khmer independent vowels (ឥ-ឱ)
  static const List<String> _independentVowels = [
    'ឥ',
    'ឦ',
    'ឧ',
    'ឨ',
    'ឩ',
    'ឪ',
    'ឫ',
    'ឬ',
    'ឭ',
    'ឮ',
    'ឯ',
    'ឰ',
    'ឱ',
    'ឲ',
    'ឳ',
  ];

  // Khmer dependent vowels and signs (for secondary sorting)
  static const List<String> _dependentVowels = [
    'ា',
    'ិ',
    'ី',
    'ឹ',
    'ឺ',
    'ុ',
    'ូ',
    'ួ',
    'ើ',
    'ឿ',
    'ៀ',
    'េ',
    'ែ',
    'ៃ',
    'ោ',
    'ៅ',
    '៉',
    '៊',
    '់',
    '្',
  ];

  // Khmer numerals (០-៩)
  static const List<String> _numerals = [
    '០',
    '១',
    '២',
    '៣',
    '៤',
    '៥',
    '៦',
    '៧',
    '៨',
    '៩',
  ];

  /// Get the sort index for a Khmer character
  /// Returns a large number for non-Khmer characters to sort them last
  static int _getCharIndex(String char) {
    // Check consonants (highest priority)
    int index = _consonants.indexOf(char);
    if (index >= 0) return index * 1000;

    // Check independent vowels
    index = _independentVowels.indexOf(char);
    if (index >= 0) return 33000 + (index * 1000);

    // Check dependent vowels (for secondary sorting)
    index = _dependentVowels.indexOf(char);
    if (index >= 0) return 50000 + (index * 10);

    // Check numerals
    index = _numerals.indexOf(char);
    if (index >= 0) return 60000 + index;

    // For non-Khmer characters, use Unicode code point
    // This will handle English, numbers, and special characters
    return 70000 + char.codeUnitAt(0);
  }

  /// Get a sortable key for a Khmer string
  /// This creates a list of indices that can be compared
  static List<int> _getSortKey(String text) {
    if (text.isEmpty) return [0];

    List<int> key = [];
    for (int i = 0; i < text.length; i++) {
      key.add(_getCharIndex(text[i]));
    }
    return key;
  }

  /// Compare two strings according to Khmer alphabetical order
  /// Returns:
  ///   - negative if a comes before b
  ///   - zero if they are equal
  ///   - positive if a comes after b
  static int compare(String a, String b) {
    List<int> keyA = _getSortKey(a);
    List<int> keyB = _getSortKey(b);

    int minLength = keyA.length < keyB.length ? keyA.length : keyB.length;

    for (int i = 0; i < minLength; i++) {
      if (keyA[i] != keyB[i]) {
        return keyA[i] - keyB[i];
      }
    }

    // If all compared characters are equal, shorter string comes first
    return keyA.length - keyB.length;
  }

  /// Sort a list of strings in Khmer alphabetical order
  static List<String> sortStrings(List<String> strings) {
    List<String> sorted = List.from(strings);
    sorted.sort((a, b) => compare(a, b));
    return sorted;
  }

  /// Sort a list of objects by a Khmer string property
  ///
  /// Example:
  /// ```dart
  /// List<Student> students = [...];
  /// KhmerCollator.sortBy(students, (s) => s.name);
  /// ```
  static void sortBy<T>(List<T> items, String Function(T) getProperty) {
    items.sort((a, b) => compare(getProperty(a), getProperty(b)));
  }
}
