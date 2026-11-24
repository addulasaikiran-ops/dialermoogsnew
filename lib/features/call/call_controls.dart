import 'package:flutter/material.dart';
class CallControls extends StatelessWidget { const CallControls({super.key,required this.children}); final List<Widget> children; @override Widget build(BuildContext context)=>Wrap(alignment:WrapAlignment.center,spacing:16,children:children); }
