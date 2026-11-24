import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/glass_surface.dart';

class RecentFilterChips extends StatelessWidget {
  const RecentFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const values = ['All', 'Missed', 'Incoming', 'Outgoing'];

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.moog;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values) ...[
            if (value != values.first) const SizedBox(width: 8),
            Semantics(
              button: true,
              selected: selected == value,
              label: '$value calls',
              child: GestureDetector(
                onTap: () => onSelected(value),
                child: GlassSurface(
                  radius: 999,
                  tint: selected == value ? t.accentA.withValues(alpha: .28) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                  child: Text(value, style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected == value ? FontWeight.w700 : FontWeight.w500,
                    color: selected == value ? t.text : t.textMuted,
                  )),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
