import 'package:flutter/material.dart';
import 'tokens.dart';
class MoogsTheme {
  static const pearl = Color(0xFFF4F1EC);
  static const midnight = Color(0xFF0A0D14);
  static const ice = Color(0xFF8CCBFA);
  static const call = Color(0xFF2FD07A);
  static const missed = Color(0xFFFF3B4E);

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: pearl,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ice,
          brightness: Brightness.light,
          surface: const Color(0xFFFAF9F6),
        ),
        useMaterial3: true,
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: midnight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ice,
          brightness: Brightness.dark,
          surface: const Color(0xFF151A26),
        ),
        useMaterial3: true,
      );
}

