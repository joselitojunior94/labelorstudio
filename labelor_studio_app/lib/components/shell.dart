import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/nav_rail.dart';
import 'package:labelor_studio_app/pages/evaluations/evaluations_page.dart';
import 'package:labelor_studio_app/pages/home/home_page.dart';
import 'package:labelor_studio_app/pages/wizard/wizard_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int idx = 0;
  void _go(int i) => setState(() => idx = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onGetStarted: () => _go(1), onSeeEvals: () => _go(2)),
      const WizardPage(),
      const EvaluationsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text('Labelor Studio'),
        actions: [
          IconButton(onPressed: () => _go(0), icon: const Icon(Icons.home_outlined)),
          IconButton(onPressed: () => _go(1), icon: const Icon(Icons.upload_outlined)),
          IconButton(onPressed: () => _go(2), icon: const Icon(Icons.fact_check_outlined)),
        ],
      ),
      body: Row(
        children: [
          NavRail(idx: idx, onSelect: _go),
          Expanded(child: pages[idx]),
        ],
      ),
    );
  }
}