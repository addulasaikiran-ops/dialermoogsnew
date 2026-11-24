import 'package:flutter/material.dart';
class NumberDisplay extends StatelessWidget { const NumberDisplay({super.key,required this.number}); final String number; @override Widget build(BuildContext context)=>Text(number.isEmpty?'Enter a number':number); }
