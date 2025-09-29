import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/gradient_background.dart';

class PageContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const PageContainer({required this.title, required this.subtitle, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              Expanded(child: child),
            ]),
          ),
        ),
      ),
    );
  }
}
