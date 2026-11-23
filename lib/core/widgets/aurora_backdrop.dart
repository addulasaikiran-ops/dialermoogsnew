import 'package:flutter/material.dart';
class AuroraBackdrop extends StatelessWidget { const AuroraBackdrop({super.key,required this.child}); final Widget child; @override Widget build(BuildContext context)=>DecoratedBox(decoration:BoxDecoration(gradient:RadialGradient(colors:[Theme.of(context).colorScheme.primary.withValues(alpha:.1),Theme.of(context).scaffoldBackgroundColor])),child:child); }
