import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../motion.dart';

/// A compact, reusable contact/call-history row with Liquid Glass interaction.
class ContactRow extends StatefulWidget {
  const ContactRow({
    super.key,
    required this.name,
    required this.number,
    required this.onCall,
    this.onTap,
    this.favorite = false,
    this.showFavorite = false,
    this.onFavorite,
    this.missed = false,
    this.relativeTime,
    this.simLabel,
    this.callType,
  });

  final String name;
  final String number;
  final VoidCallback onCall;
  final VoidCallback? onTap;
  final bool favorite;
  final bool showFavorite;
  final VoidCallback? onFavorite;
  final bool missed;
  final String? relativeTime;
  final String? simLabel;
  final int? callType;

  @override
  State<ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<ContactRow> {
  bool _pressed = false;

  String get _initials {
    final words = widget.name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final value = words.first;
      return value.substring(0, value.length > 1 ? 2 : 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.moog;
    final detailParts = <Widget>[];
    if (widget.number.isNotEmpty && widget.number.trim() != widget.name.trim()) {
      detailParts.add(Text(widget.number, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: t.textMuted)));
    }
    if ((widget.relativeTime ?? '').isNotEmpty) {
      detailParts.add(Text(widget.relativeTime!, style: TextStyle(fontSize: 13, color: t.textMuted)));
      final direction = switch (widget.callType) {
        1 => 'Incoming call',
        2 => 'Outgoing call',
        3 => 'Missed call',
        _ => null,
      };
      if (direction != null) {
        detailParts.add(Semantics(
          label: direction,
          child: CustomPaint(
            size: const Size.square(13),
            painter: _CallDirectionPainter(
              callType: widget.callType!,
              color: widget.callType == 3 ? t.missed : t.textMuted,
            ),
          ),
        ));
      }
    }
    if ((widget.simLabel ?? '').isNotEmpty) {
      detailParts.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: t.glassFillLo,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.borderLo, width: .7),
        ),
        child: Text(widget.simLabel!, style: TextStyle(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w600)),
      ));
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .98 : 1,
        duration: moogMs(context, 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: moogMs(context, 110),
          constraints: const BoxConstraints(minHeight: 64),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: _pressed ? t.glassFillLo.withValues(alpha: .55) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [t.borderHi, t.borderLo],
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: t.glassFillHi),
                  child: Center(
                    child: Text(_initials, style: TextStyle(
                      color: t.text, fontSize: 14, fontWeight: FontWeight.w700,
                    )),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, height: 1.2, fontWeight: FontWeight.w500,
                        color: widget.missed ? t.missed : t.text)),
                    if (detailParts.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: detailParts,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.showFavorite)
                Semantics(
                  button: true,
                  label: widget.favorite ? 'Remove ${widget.name} from favorites' : 'Add ${widget.name} to favorites',
                  child: IconButton(
                    tooltip: widget.favorite ? 'Remove favorite' : 'Add favorite',
                    onPressed: widget.onFavorite,
                    icon: Icon(widget.favorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: t.accentA),
                  ),
                ),
              Semantics(
                button: true,
                label: 'Call ${widget.name}',
                onTap: widget.onCall,
                child: ExcludeSemantics(
                  child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: 'Call ${widget.name}',
                    onPressed: widget.onCall,
                    icon: Icon(Icons.call_rounded, color: t.call, size: 21),
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _CallDirectionPainter extends CustomPainter {
  const _CallDirectionPainter({required this.callType, required this.color});

  final int callType;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 13;
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (callType) {
      case 1: // Incoming: arrow points into the handset.
        path.moveTo(6.5, 2);
        path.lineTo(6.5, 10.5);
        path.moveTo(3.5, 7.5);
        path.lineTo(6.5, 10.5);
        path.lineTo(9.5, 7.5);
        break;
      case 2: // Outgoing: arrow points away from the handset.
        path.moveTo(3, 10);
        path.lineTo(10, 3);
        path.moveTo(5.5, 3);
        path.lineTo(10, 3);
        path.lineTo(10, 7.5);
        break;
      case 3: // Missed: descending arrow.
        path.moveTo(3, 3);
        path.lineTo(10, 10);
        path.moveTo(5.5, 10);
        path.lineTo(10, 10);
        path.lineTo(10, 5.5);
        break;
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CallDirectionPainter oldDelegate) =>
      oldDelegate.callType != callType || oldDelegate.color != color;
}
