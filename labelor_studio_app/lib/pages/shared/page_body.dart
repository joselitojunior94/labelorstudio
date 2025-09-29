import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/gradient_background.dart';

class PageBody extends StatelessWidget {
  const PageBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(padding: const EdgeInsets.all(18), child: child),
        ),
      ),
    );
  }
}