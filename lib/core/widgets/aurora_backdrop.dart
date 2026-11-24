import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../motion.dart';

/// A low-cost animated atmosphere for Moog's Phone screens.
///
/// Uses radial gradients rather than blur filters. The backdrop is isolated
/// from foreground interaction so keypad updates do not repaint its contents.
class AuroraBackdrop extends StatefulWidget {
  const AuroraBackdrop({super.key});

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state != AppLifecycleState.resumed) {
      _drift.stop();
    } else if (moogMs(context, 40000) > Duration.zero) {
      _drift.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = moogMs(context, 40000);
    _drift.duration = duration;
    if (duration == Duration.zero) {
      _drift.stop();
      _drift.value = 0;
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _drift.dispose();
    super.dispose();
  }

  Alignment _alignment(double phase, double x, double y) => Alignment(
        x + math.sin(phase * math.pi * 2) * .12,
        y + math.cos(phase * math.pi * 2) * .10,
      );

  Widget _orb(Color color, Alignment alignment, double size) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: size,
        heightFactor: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: .30),
                color.withValues(alpha: .12),
                color.withValues(alpha: 0),
              ],
              stops: const [0, .48, 1],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.moog;
    final colors = t.orbs;
    final orbA = colors.isNotEmpty ? colors[0] : t.accentA;
    final orbB = colors.length > 1 ? colors[1] : t.accentB;
    final orbC = colors.length > 2 ? colors[2] : t.accentA;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _drift,
        child: IgnorePointer(
          child: Image.asset(
            'assets/images/grain.png',
            repeat: ImageRepeat.repeat,
            filterQuality: FilterQuality.low,
            opacity: const AlwaysStoppedAnimation(.035),
          ),
        ),
        builder: (context, grain) {
          final phase = _drift.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [t.bgTop, t.bgBottom],
                  ),
                ),
              ),
              _orb(orbA, _alignment(phase, -.72, -.72), .92),
              _orb(orbB, _alignment(phase + .34, .78, -.12), .84),
              _orb(orbC, _alignment(phase + .68, -.18, .88), .96),
              if (grain != null) grain,
            ],
          );
        },
      ),
    );
  }
}
