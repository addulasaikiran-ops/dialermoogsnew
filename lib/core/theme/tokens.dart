import 'package:flutter/material.dart';

@immutable
class MoogTokens extends ThemeExtension<MoogTokens> {
  const MoogTokens({
    required this.bgTop,
    required this.bgBottom,
    required this.orbs,
    required this.glassFillHi,
    required this.glassFillLo,
    required this.borderHi,
    required this.borderLo,
    required this.shadow,
    required this.text,
    required this.textMuted,
    required this.accentA,
    required this.accentB,
  });

  final Color bgTop;
  final Color bgBottom;
  final Color glassFillHi;
  final Color glassFillLo;
  final Color borderHi;
  final Color borderLo;
  final Color shadow;
  final Color text;
  final Color textMuted;
  final Color accentA;
  final Color accentB;
  final List<Color> orbs;

  static const pearl = MoogTokens(
    bgTop: Color(0xFFF4F1EC),
    bgBottom: Color(0xFFE9E6F0),
    orbs: [Color(0x668CCBFA), Color(0x44B9A7E8), Color(0x33F3C6B8)],
    glassFillHi: Color(0xB3FFFFFF),
    glassFillLo: Color(0x73FFFFFF),
    borderHi: Color(0xE6FFFFFF),
    borderLo: Color(0x55FFFFFF),
    shadow: Color(0x1F000000),
    text: Color(0xFF1B1D22),
    textMuted: Color(0x991B1D22),
    accentA: Color(0xFF8CCBFA),
    accentB: Color(0xFF2FD07A),
  );

  static const midnight = MoogTokens(
    bgTop: Color(0xFF0A0D14),
    bgBottom: Color(0xFF151A26),
    orbs: [Color(0x338CCBFA), Color(0x33B9A7E8), Color(0x22FF6B78)],
    glassFillHi: Color(0x24FFFFFF),
    glassFillLo: Color(0x0FFFFFFF),
    borderHi: Color(0x59FFFFFF),
    borderLo: Color(0x1FFFFFFF),
    shadow: Color(0x66000000),
    text: Color(0xFFEEF1F7),
    textMuted: Color(0x99EEF1F7),
    accentA: Color(0xFF8CCBFA),
    accentB: Color(0xFF2FD07A),
  );

  @override
  MoogTokens copyWith({
    Color? bgTop,
    Color? bgBottom,
    List<Color>? orbs,
    Color? glassFillHi,
    Color? glassFillLo,
    Color? borderHi,
    Color? borderLo,
    Color? shadow,
    Color? text,
    Color? textMuted,
    Color? accentA,
    Color? accentB,
  }) =>
      MoogTokens(
        bgTop: bgTop ?? this.bgTop,
        bgBottom: bgBottom ?? this.bgBottom,
        orbs: orbs ?? this.orbs,
        glassFillHi: glassFillHi ?? this.glassFillHi,
        glassFillLo: glassFillLo ?? this.glassFillLo,
        borderHi: borderHi ?? this.borderHi,
        borderLo: borderLo ?? this.borderLo,
        shadow: shadow ?? this.shadow,
        text: text ?? this.text,
        textMuted: textMuted ?? this.textMuted,
        accentA: accentA ?? this.accentA,
        accentB: accentB ?? this.accentB,
      );

  @override
  MoogTokens lerp(ThemeExtension<MoogTokens>? other, double t) {
    if (other is! MoogTokens) return this;
    return MoogTokens(
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      orbs: List<Color>.generate(
        orbs.length,
        (i) => Color.lerp(
          orbs[i],
          other.orbs[i < other.orbs.length ? i : other.orbs.length - 1],
          t,
        )!,
      ),
      glassFillHi: Color.lerp(glassFillHi, other.glassFillHi, t)!,
      glassFillLo: Color.lerp(glassFillLo, other.glassFillLo, t)!,
      borderHi: Color.lerp(borderHi, other.borderHi, t)!,
      borderLo: Color.lerp(borderLo, other.borderLo, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentA: Color.lerp(accentA, other.accentA, t)!,
      accentB: Color.lerp(accentB, other.accentB, t)!,
    );
  }
}

extension MoogThemeContext on BuildContext {
  MoogTokens get moog => Theme.of(this).extension<MoogTokens>()!;
}

abstract final class MoogRadii {
  static const double sheet = 32;
  static const double card = 24;
  static const double pill = 999;
}

abstract final class MoogSpacing {
  static const double step = 8;
  static const double x1 = 8;
  static const double x2 = 16;
  static const double x3 = 24;
  static const double x4 = 32;
  static const double x5 = 40;
}
