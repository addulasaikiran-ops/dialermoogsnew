import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = false,
    this.shadow = false,
    this.tint,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final bool blur;
  final bool shadow;
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.moog;
    final shape = BorderRadius.circular(radius);
    Widget fill = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint ?? t.glassFillHi, tint == null ? t.glassFillLo : tint!.withValues(alpha: tint!.a * .55)],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (blur) {
      fill = ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: fill,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.borderHi, t.borderLo],
        ),
        boxShadow: shadow
            ? [BoxShadow(color: t.shadow, blurRadius: 28, offset: const Offset(0, 12))]
            : const [],
      ),
      padding: const EdgeInsets.all(1),
      child: fill,
    );
  }
}
