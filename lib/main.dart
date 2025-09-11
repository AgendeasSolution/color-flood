import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'pages/splash_page.dart';
import 'assets/styles/app_theme.dart';

void main() {
  runApp(const ColorFloodApp());
}

/// Main application widget
class ColorFloodApp extends StatelessWidget {
  const ColorFloodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
      // Ensure no default splash screen interference
      builder: (context, child) {
        return child ?? const SplashPage();
      },
    );
  }
}

