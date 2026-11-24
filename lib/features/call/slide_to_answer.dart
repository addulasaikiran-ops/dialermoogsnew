import 'package:flutter/material.dart';
class SlideToAnswer extends StatelessWidget { const SlideToAnswer({super.key,required this.onAnswer}); final VoidCallback onAnswer; @override Widget build(BuildContext context)=>FilledButton(onPressed:onAnswer,child:const Text('Answer')); }
