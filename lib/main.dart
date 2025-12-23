import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uniclip/engine/engine.dart';
import 'package:uniclip/ui/home/uniclip_desk_screen.dart';
import 'package:uniclip/service/background_service.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    // Determine identity for UI display
    await Engine().identity.initialize();
    await BackgroundService.initialize();
  } else {
    // Desktop: Run Engine Locally
    await Engine().start();

    // Window Manager for Minimize to Tray
    await windowManager.ensureInitialized();
    windowManager.setPreventClose(true);
  }

  runApp(const UniclipApp());
}

class UniclipApp extends StatelessWidget {
  const UniclipApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4ADE80); // Vibrant Green
    const backgroundColor = Colors.black;
    const surfaceColor = Color(0xFF161616);

    return MaterialApp(
      title: 'Uniclip',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Force Dark Mode
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        primaryColor: primaryColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: primaryColor,
          surface: surfaceColor,
          background: backgroundColor,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        useMaterial3: true,

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // Card Theme (Highly rounded)
        cardTheme: const CardThemeData(
          // Changed to CardThemeData
          color: surfaceColor,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            side: BorderSide(color: Color(0xFF2A2A2A), width: 1),
          ),
        ),

        // Button Themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black, // Dark text on green button
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: const StadiumBorder(), // Pill shape
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF333333)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: const StadiumBorder(),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
        ),

        // Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor),
          ),
        ),

        // Dialog Theme
        dialogTheme: DialogThemeData(
          // Changed to DialogThemeData
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF333333),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const UniclipDeskScreen(),
    );
  }
}
