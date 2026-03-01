import 'package:flutter/material.dart';
import 'app_theme_color.dart';

// ---------------------------------------------------------------------------
// Colour palette
// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  // Default colors (Blue theme)
  static const Color primary = Color(0xFF1E5ADB);
  static const Color primaryLight = Color(0xFFD6E4FF);
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF5F7FA);
  static const Color border = Color(0xFFE3E8F0);
  static const Color textPrimary = Color(0xFF1A2340);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color danger = Color(0xFFD93025);
  static const Color success = Color(0xFF1A8A4A);

  // Theme color variations
  static Color getPrimaryColor(AppThemeColor themeColor) {
    switch (themeColor) {
      case AppThemeColor.blue:
        return const Color(0xFF1E5ADB);
      case AppThemeColor.red:
        return const Color(0xFFDC2626);
      case AppThemeColor.orange:
        return const Color(0xFFEA580C);
      case AppThemeColor.pink:
        return const Color(0xFFEC4899);
      case AppThemeColor.green:
        return const Color(0xFF059669);
    }
  }

  static Color getPrimaryLightColor(AppThemeColor themeColor) {
    switch (themeColor) {
      case AppThemeColor.blue:
        return const Color(0xFFD6E4FF);
      case AppThemeColor.red:
        return const Color(0xFFFEE2E2);
      case AppThemeColor.orange:
        return const Color(0xFFFFEDD5);
      case AppThemeColor.pink:
        return const Color(0xFFFCE7F3);
      case AppThemeColor.green:
        return const Color(0xFFD1FAE5);
    }
  }
}

// ---------------------------------------------------------------------------
// Text styles
// ---------------------------------------------------------------------------
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}

// ---------------------------------------------------------------------------
// Dimension tokens
// ---------------------------------------------------------------------------
class AppSizes {
  AppSizes._();

  // Border radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;

  // Padding / spacing
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;

  // Icons
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 28.0;

  // Elevation
  static const double cardElevation = 0.0;
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------
class AppTheme {
  AppTheme._();

  static ThemeData getTheme(AppThemeColor themeColor) {
    final primaryColor = AppColors.getPrimaryColor(themeColor);
    final primaryLightColor = AppColors.getPrimaryLightColor(themeColor);

    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: AppColors.white,
      secondary: primaryLightColor,
      onSecondary: primaryColor,
      error: AppColors.danger,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Kantumruy Pro',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: primaryColor,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Kantumruy Pro',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),

      // Card — use ThemeData.cardColor + shape workaround for older APIs
      cardColor: AppColors.white,

      // Filled / Elevated buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: AppColors.white,
          textStyle: const TextStyle(
            fontFamily: 'Kantumruy Pro',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLg,
            vertical: AppSizes.paddingMd,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: AppColors.white,
          textStyle: const TextStyle(
            fontFamily: 'Kantumruy Pro',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      ),

      // Text button (e.g., Cancel in dialogs)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'Kantumruy Pro',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd,
            vertical: AppSizes.paddingSm,
          ),
        ),
      ),

      // Input decoration (text fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingMd,
        ),
        labelStyle: AppTextStyles.caption,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: AppColors.white,
      ),

      // Progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColor),

      // SnackBar
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(color: AppColors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Backward compatibility - default blue theme
  static ThemeData get themeData => getTheme(AppThemeColor.blue);
}
