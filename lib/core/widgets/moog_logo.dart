import 'package:flutter/material.dart';
class MoogLogo extends StatelessWidget { const MoogLogo({super.key,this.size=40}); final double size; @override Widget build(BuildContext context)=>Icon(Icons.call_rounded,size:size,color:Theme.of(context).colorScheme.primary); }
