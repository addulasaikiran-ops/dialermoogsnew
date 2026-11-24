import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tokens.dart';
import '../../core/motion.dart';
import '../../core/widgets/glass_surface.dart';

class KeypadKey extends StatefulWidget {
  const KeypadKey({
    super.key,
    required this.digit,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.size = 84,
  });

  final String digit;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double size;

  @override
  State<KeypadKey> createState() => _KeypadKeyState();
}

class _KeypadKeyState extends State<KeypadKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.moog;
    final spokenLabel = switch (widget.digit) {
      '*' => 'Star',
      '#' => 'Pound',
      _ => 'Digit ${widget.digit}',
    };
    return Semantics(
      button: true,
      label: spokenLabel,
      child: ExcludeSemantics(
        child: SizedBox(
      width: widget.size,
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: _pressed ? .97 : 1,
            duration: moogMs(context, 300),
            curve: Curves.easeOutBack,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _pressed
                    ? [BoxShadow(color: t.accentA.withValues(alpha: .16), blurRadius: 18, spreadRadius: 1)]
                    : const [],
              ),
              child: GlassSurface(
                radius: 999,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.digit, style: TextStyle(
                      fontSize: widget.size < 56 ? 24 : 34,
                      height: 1,
                      fontWeight: FontWeight.w200,
                      color: t.text,
                    )),
                    if (widget.label.isNotEmpty && widget.size >= 56) ...[
                      const SizedBox(height: 3),
                      Text(widget.label, style: TextStyle(
                        fontSize: 10,
                        height: 1,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w500,
                        color: t.textMuted,
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }
}
