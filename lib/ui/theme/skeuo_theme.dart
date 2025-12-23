import 'package:flutter/material.dart';

class SkeuoTheme {
  // Colors
  static const Color deskSurface = Color(0xFF2C2C2E); // Dark Industrial Mat
  static const Color paperWhite = Color(0xFFF2F2F7);
  static const Color paperText = Color(0xFF1C1C1E);
  static const Color metalGrey = Color(0xFF48484A);
  static const Color metalHighlight = Color(0xFF636366);
  static const Color accentRed = Color(0xFFFF453A); // Launch button red
  static const Color accentGreen = Color(0xFF32D74B); // LED Green
  static const Color accentBlue = Color(0xFF0A84FF); // LED Blue

  // Text Styles
  static const TextStyle headerText = TextStyle(
    color: Colors.white70,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    shadows: [
      Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1)),
    ],
  );

  static const TextStyle paperTitle = TextStyle(
    color: paperText,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'Courier', // Typewriter feel
  );

  static const TextStyle paperBody = TextStyle(
    color: paperText,
    fontSize: 14,
    fontFamily: 'Courier',
    height: 1.4,
  );

  // Shadows
  static List<BoxShadow> deepShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.6),
      offset: const Offset(4, 8),
      blurRadius: 12,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      offset: const Offset(1, 2),
      blurRadius: 4,
    ),
  ];

  static List<BoxShadow> pressedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      offset: const Offset(1, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
}
