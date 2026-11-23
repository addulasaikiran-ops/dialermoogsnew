import 'package:flutter/material.dart';

import 'tokens.dart';

class MoogsTheme {
  static const pearl = Color(0xFFF4F1EC);
  static const midnight = Color(0xFF0A0D14);
  static const ice = Color(0xFF8CCBFA);
  static const call = Color(0xFF2FD07A);
  static const missed = Color(0xFFFF3B4E);

  static ThemeData get light => _build(
        brightness: Brightness.light,
        tokens: MoogTokens.pearl,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        tokens: MoogTokens.midnight,
      );

  static ThemeData _build({
    required Brightness brightness,
    required MoogTokens tokens,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.accentA,
      brightness: brightness,
      surface: tokens.glassFillHi,
    ).copyWith(
      primary: tokens.accentA,
      secondary: tokens.accentB,
      surface: tokens.bgBottom,
      onSurface: tokens.text,
    );

    return ThemeData(
      brightness: brightness,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: tokens.bgTop,
      colorScheme: scheme,
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}
