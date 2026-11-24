import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class NumberDisplay extends StatelessWidget {
  const NumberDisplay({super.key, required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final t = context.moog;
    if (number.isEmpty) {
      return Text('Enter number', style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400, color: t.textMuted,
        letterSpacing: .4,
      ));
    }
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(number, maxLines: 1, style: TextStyle(
          fontSize: 36, height: 1.15, fontWeight: FontWeight.w200,
          letterSpacing: 3, color: t.text,
        )),
      ),
    );
  }
}
