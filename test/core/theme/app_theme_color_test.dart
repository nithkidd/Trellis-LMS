import 'package:flutter_test/flutter_test.dart';
import 'package:lms/core/theme/app_theme_color.dart';

void main() {
  group('AppThemeColor Tests', () {
    test('should have correct display names', () {
      expect(AppThemeColor.blue.displayName, 'ខៀវ (Blue)');
      expect(AppThemeColor.red.displayName, 'ក្រហម (Red)');
      expect(AppThemeColor.orange.displayName, 'ទឹកក្រូច (Orange)');
      expect(AppThemeColor.pink.displayName, 'ផ្កាឈូក (Pink)');
      expect(AppThemeColor.green.displayName, 'បៃតង (Green)');
    });

    test('should have correct keys', () {
      expect(AppThemeColor.blue.key, 'blue');
      expect(AppThemeColor.red.key, 'red');
      expect(AppThemeColor.orange.key, 'orange');
      expect(AppThemeColor.pink.key, 'pink');
      expect(AppThemeColor.green.key, 'green');
    });

    test('should convert from key correctly', () {
      expect(AppThemeColorExtension.fromKey('blue'), AppThemeColor.blue);
      expect(AppThemeColorExtension.fromKey('red'), AppThemeColor.red);
      expect(AppThemeColorExtension.fromKey('orange'), AppThemeColor.orange);
      expect(AppThemeColorExtension.fromKey('pink'), AppThemeColor.pink);
      expect(AppThemeColorExtension.fromKey('green'), AppThemeColor.green);
    });

    test('should default to blue for invalid key', () {
      expect(AppThemeColorExtension.fromKey('invalid'), AppThemeColor.blue);
      expect(AppThemeColorExtension.fromKey(''), AppThemeColor.blue);
    });

    test('should have all 5 theme colors', () {
      expect(AppThemeColor.values.length, 5);
    });
  });
}
