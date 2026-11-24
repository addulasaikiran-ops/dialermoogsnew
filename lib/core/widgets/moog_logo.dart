import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Temporary local missed-call count source. The Call Log provider will
/// update this notifier in a later integration slice.
final ValueNotifier<int> moogMissedCount = ValueNotifier<int>(0);

class MoogLogo extends StatelessWidget {
  const MoogLogo({
    super.key,
    this.size = 48,
    this.missedCount,
    this.monochrome = false,
  });

  final double size;

  /// When omitted, the logo listens to [moogMissedCount].
  final int? missedCount;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final tokens = context.moog;
    final normal = monochrome ? tokens.text : tokens.accentA;
    const missedColor = Color(0xFFFF3B4E);

    return ValueListenableBuilder<int>(
      valueListenable: moogMissedCount,
      builder: (context, liveCount, _) {
        final count = missedCount ?? liveCount;
        final missed = count > 0;
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            begin: normal,
            end: missed ? missedColor : normal,
          ),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, animatedColor, _) {
            final primary = animatedColor ?? normal;
            final secondary = monochrome
                ? primary
                : (missed ? const Color(0xFFE77B78) : tokens.accentB);
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MoogLogoPainter(
                        primary: primary,
                        secondary: secondary,
                        highlight: monochrome
                            ? primary.withValues(alpha: .45)
                            : Colors.white.withValues(alpha: .78),
                        missed: missed && !monochrome,
                      ),
                    ),
                  ),
                  if (count > 0 && !monochrome)
                    Positioned(
                      right: -size * .10,
                      top: -size * .10,
                      child: _MissedCountBadge(count: count, size: size),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MissedCountBadge extends StatelessWidget {
  const _MissedCountBadge({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final diameter = size * .34;
    return Container(
      constraints: BoxConstraints(minWidth: diameter, minHeight: diameter),
      padding: EdgeInsets.symmetric(horizontal: size * .045),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B4E),
        borderRadius: BorderRadius.circular(diameter),
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: size * .035,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .18,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MoogLogoPainter extends CustomPainter {
  const _MoogLogoPainter({
    required this.primary,
    required this.secondary,
    required this.highlight,
    required this.missed,
  });

  final Color primary;
  final Color secondary;
  final Color highlight;
  final bool missed;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide;
    final path = Path()
      ..moveTo(scale * .12, scale * .80)
      ..lineTo(scale * .12, scale * .22)
      ..lineTo(scale * .50, scale * .62)
      ..lineTo(scale * .88, scale * .22)
      ..lineTo(scale * .88, scale * .80);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * .11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, secondary],
      ).createShader(Offset.zero & Size(scale, scale));

    if (missed) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * .15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFF3B4E).withValues(alpha: .16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(path, glow);
    }

    canvas.drawPath(path, stroke);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * .018
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = highlight;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _MoogLogoPainter oldDelegate) =>
      primary != oldDelegate.primary ||
      secondary != oldDelegate.secondary ||
      highlight != oldDelegate.highlight ||
      missed != oldDelegate.missed;
}
