import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A lightweight Liquid Glass surface.
///
/// Keep [blur] and [shadow] disabled for repeated controls such as keypad keys.
/// On Redmi 9 Activ, limit backdrop-blurred surfaces to two per screen.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = false,
    this.shadow = false,
  });

  final Widget child;
  final double radius;
  final bool blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final t = context.moog;
    final innerRadius = (radius - 1).clamp(0.0, radius).toDouble();

    Widget inner = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(innerRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.glassFillHi, t.glassFillLo],
        ),
      ),
      child: child,
    );

    if (blur) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: inner,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.borderHi, t.borderLo],
        ),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: t.shadow,
                  blurRadius: 60,
                  offset: const Offset(0, 24),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: inner,
      ),
    );
  }
}
