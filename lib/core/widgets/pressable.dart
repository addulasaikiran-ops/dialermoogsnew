import 'package:flutter/material.dart';
class Pressable extends StatelessWidget { const Pressable({super.key,required this.child,required this.onPressed}); final Widget child; final VoidCallback onPressed; @override Widget build(BuildContext context)=>InkWell(onTap:onPressed,child:child); }
