import 'package:flutter/material.dart';
class GlassSurface extends StatelessWidget { const GlassSurface({super.key,required this.child}); final Widget child; @override Widget build(BuildContext context)=>Container(decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface.withValues(alpha:.75),borderRadius:BorderRadius.circular(24)),child:child); }
