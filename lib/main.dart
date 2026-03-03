import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:trellis/features/dashboard/views/main_dashboard_screen.dart';
import 'package:trellis/core/theme/app_theme.dart';
import 'package:trellis/core/theme/theme_provider.dart';
import 'package:trellis/core/database/database_helper.dart';
import 'package:trellis/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory based on platform
  if (kIsWeb) {
    // Use web-compatible database
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    // Use FFI for desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize the database before running the app
  await DatabaseHelper.instance.database;

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = ref.watch(themeNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trellis',
      theme: AppTheme.getTheme(themeColor),
      home: const _SplashWrapper(),
    );
  }
}

class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper();

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Hide splash screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }
    return const MainDashboardScreen();
  }
}
