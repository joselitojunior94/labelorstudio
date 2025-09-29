
import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({required this.child});
  
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFEAF2FF), Color(0xFFF7FAFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: child,
    );
  }
}