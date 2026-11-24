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
    required this.call,
    required this.callGradient,
    required this.end,
    required this.missed,
    required this.onMissed,
    required this.logoSilver,
    required this.logoBlue,
    required this.logoSlate,
  });

  final Color bgTop, bgBottom, glassFillHi, glassFillLo, borderHi, borderLo;
  final Color shadow, text, textMuted, accentA, accentB;
  final Color call, end, missed, onMissed, logoSilver, logoBlue, logoSlate;
  final List<Color> callGradient;
  final List<Color> orbs;

  @override
  MoogTokens copyWith({
    Color? bgTop, Color? bgBottom, List<Color>? orbs,
    Color? glassFillHi, Color? glassFillLo, Color? borderHi,
    Color? borderLo, Color? shadow, Color? text, Color? textMuted,
    Color? accentA, Color? accentB, Color? call, List<Color>? callGradient,
    Color? end, Color? missed, Color? onMissed, Color? logoSilver, Color? logoBlue, Color? logoSlate,
  }) => MoogTokens(
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
    call: call ?? this.call,
    callGradient: callGradient ?? this.callGradient,
    end: end ?? this.end,
    missed: missed ?? this.missed,
    onMissed: onMissed ?? this.onMissed,
    logoSilver: logoSilver ?? this.logoSilver,
    logoBlue: logoBlue ?? this.logoBlue,
    logoSlate: logoSlate ?? this.logoSlate,
  );

  @override
  MoogTokens lerp(covariant MoogTokens? other, double t) {
    if (other == null) return this;
    final count = orbs.length > other.orbs.length ? orbs.length : other.orbs.length;
    final colors = List<Color>.generate(count, (i) {
      final a = orbs.isEmpty ? Colors.transparent : orbs[i < orbs.length ? i : orbs.length - 1];
      final b = other.orbs.isEmpty ? Colors.transparent : other.orbs[i < other.orbs.length ? i : other.orbs.length - 1];
      return Color.lerp(a, b, t)!;
    });
    return MoogTokens(
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      orbs: colors,
      glassFillHi: Color.lerp(glassFillHi, other.glassFillHi, t)!,
      glassFillLo: Color.lerp(glassFillLo, other.glassFillLo, t)!,
      borderHi: Color.lerp(borderHi, other.borderHi, t)!,
      borderLo: Color.lerp(borderLo, other.borderLo, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentA: Color.lerp(accentA, other.accentA, t)!,
      accentB: Color.lerp(accentB, other.accentB, t)!,
      call: Color.lerp(call, other.call, t)!,
      callGradient: List<Color>.generate(3, (i) => Color.lerp(callGradient[i], other.callGradient[i], t)!),
      end: Color.lerp(end, other.end, t)!,
      missed: Color.lerp(missed, other.missed, t)!,
      onMissed: Color.lerp(onMissed, other.onMissed, t)!,
      logoSilver: Color.lerp(logoSilver, other.logoSilver, t)!,
      logoBlue: Color.lerp(logoBlue, other.logoBlue, t)!,
      logoSlate: Color.lerp(logoSlate, other.logoSlate, t)!,
    );
  }
}

extension MoogThemeContext on BuildContext {
  MoogTokens get moog => Theme.of(this).extension<MoogTokens>()!;
}
