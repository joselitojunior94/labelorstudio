import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/glass_card.dart';
import 'package:labelor_studio_app/components/gradient_background.dart';
import 'package:labelor_studio_app/components/chip_comp.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onGetStarted, required this.onSeeEvals});
  final VoidCallback onGetStarted;
  final VoidCallback onSeeEvals;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1000;
              final hero = GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Orchestrate human assessments at scale',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload CSVs, define mappings, invite judges and reviewers, and track metrics like Cohen’s κ.',
                    ),
                    const SizedBox(height: 16),
                    Wrap(spacing: 12, runSpacing: 12, children: const [
                      ChipComp(icon: Icons.cloud_upload, label: 'Upload & mapping'),
                      ChipComp(icon: Icons.rule, label: 'Judgment & review'),
                      ChipComp(icon: Icons.analytics_outlined, label: 'Automatic metrics'),
                      ChipComp(icon: Icons.download_outlined, label: 'Export CSV/JSON'),
                    ]),
                  ]),
                ),
              );

              final cta = GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Start now', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onGetStarted,
                      icon: const Icon(Icons.upload_outlined),
                      label: const Text('Create Dataset'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onSeeEvals,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('See Evaluations'),
                    ),
                  ]),
                ),
              );

              return Padding(
                padding: const EdgeInsets.all(20),
                child: wide
                    ? Row(children: [Expanded(child: hero), const SizedBox(width: 24), Expanded(child: cta)])
                    : SingleChildScrollView(child: Column(children: [hero, const SizedBox(height: 16), cta])),
              );
            },
          ),
        ),
      ),
    );
  }
}