enum AppThemeColor { blue, red, orange, pink, green }

extension AppThemeColorExtension on AppThemeColor {
  String get displayName {
    switch (this) {
      case AppThemeColor.blue:
        return 'ខៀវ (Blue)';
      case AppThemeColor.red:
        return 'ក្រហម (Red)';
      case AppThemeColor.orange:
        return 'ទឹកក្រូច (Orange)';
      case AppThemeColor.pink:
        return 'ផ្កាឈូក (Pink)';
      case AppThemeColor.green:
        return 'បៃតង (Green)';
    }
  }

  String get key {
    switch (this) {
      case AppThemeColor.blue:
        return 'blue';
      case AppThemeColor.red:
        return 'red';
      case AppThemeColor.orange:
        return 'orange';
      case AppThemeColor.pink:
        return 'pink';
      case AppThemeColor.green:
        return 'green';
    }
  }

  static AppThemeColor fromKey(String key) {
    switch (key) {
      case 'red':
        return AppThemeColor.red;
      case 'orange':
        return AppThemeColor.orange;
      case 'pink':
        return AppThemeColor.pink;
      case 'green':
        return AppThemeColor.green;
      case 'blue':
      default:
        return AppThemeColor.blue;
    }
  }
}
