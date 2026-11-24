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
  }) {
    return MoogTokens(
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
  }

  @override
  MoogTokens lerp(covariant MoogTokens? other, double t) {
    if (other == null) return this;
    return MoogTokens(
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      orbs: List<Color>.generate(
        orbs.length,
        (index) => Color.lerp(
          orbs[index],
          other.orbs[index < other.orbs.length ? index : other.orbs.length - 1],
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
