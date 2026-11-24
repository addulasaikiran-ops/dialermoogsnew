import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/glass_surface.dart';

class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.missedCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int missedCount;

  static const _labels = ['Favorites', 'Recents', 'Contacts', 'Keypad'];

  @override
  Widget build(BuildContext context) {
    final t = context.moog;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 4;
        final indicatorWidth = itemWidth - 8;
        return GlassSurface(
          radius: 999,
          blur: true,
          shadow: true,
          child: SizedBox(
            height: 64,
            child: Stack(
              children: [
                AnimatedAlign(
                  alignment: Alignment(-1 + (selectedIndex * 2 / 3), 0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  child: SizedBox(
                    width: indicatorWidth,
                    height: 52,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: t.accentA.withValues(alpha: .18),
                        border: Border.all(color: t.accentA.withValues(alpha: .18)),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(4, (index) {
                    final selected = selectedIndex == index;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: selected,
                        label: _labels[index],
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => onSelected(index),
                          child: SizedBox(
                            height: 64,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MoogNavIcon(
                                      type: MoogNavIconType.values[index],
                                      color: selected ? t.text : t.textMuted,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _labels[index],
                                      style: TextStyle(
                                        fontSize: 9,
                                        height: 1,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                        color: selected ? t.text : t.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                if (index == 1 && missedCount > 0)
                                  Positioned(
                                    top: 8,
                                    right: itemWidth * .22,
                                    child: Container(
                                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF3B4E),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        missedCount > 99 ? '99+' : '$missedCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum MoogNavIconType { favorites, recents, contacts, keypad }

class MoogNavIcon extends StatelessWidget {
  const MoogNavIcon({super.key, required this.type, required this.color, this.size = 24});
  final MoogNavIconType type;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _MoogNavIconPainter(type, color),
  );
}

class _MoogNavIconPainter extends CustomPainter {
  const _MoogNavIconPainter(this.type, this.color);
  final MoogNavIconType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.save();
    canvas.scale(scale);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (type) {
      case MoogNavIconType.favorites:
        path.moveTo(12, 3.2);
        path.lineTo(14.7, 8.7);
        path.lineTo(20.8, 9.6);
        path.lineTo(16.4, 13.9);
        path.lineTo(17.4, 20);
        path.lineTo(12, 17.1);
        path.lineTo(6.6, 20);
        path.lineTo(7.6, 13.9);
        path.lineTo(3.2, 9.6);
        path.lineTo(9.3, 8.7);
        path.close();
        canvas.drawPath(path, p);
      case MoogNavIconType.recents:
        canvas.drawCircle(const Offset(12, 12), 8.5, p);
        path.moveTo(12, 7);
        path.lineTo(12, 12);
        path.lineTo(15.5, 14);
        canvas.drawPath(path, p);
        path.reset();
        path.moveTo(4.2, 7.5);
        path.lineTo(4.2, 3.8);
        path.lineTo(7.8, 3.8);
        canvas.drawPath(path, p);
      case MoogNavIconType.contacts:
        canvas.drawCircle(const Offset(12, 8), 3.2, p);
        path.moveTo(4.5, 20);
        path.cubicTo(4.8, 15.7, 7.5, 13.5, 12, 13.5);
        path.cubicTo(16.5, 13.5, 19.2, 15.7, 19.5, 20);
        canvas.drawPath(path, p);
      case MoogNavIconType.keypad:
        for (final x in [6.0, 12.0, 18.0]) {
          for (final y in [6.0, 12.0, 18.0]) {
            canvas.drawCircle(Offset(x, y), 1.45, p);
          }
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoogNavIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}
