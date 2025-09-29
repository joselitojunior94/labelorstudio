import 'package:flutter/material.dart';

class NavRail extends StatelessWidget {
  final int idx;
  final ValueChanged<int> onSelect;

  const NavRail({required this.idx, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: idx,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.home_outlined), label: Text('Home')),
        NavigationRailDestination(icon: Icon(Icons.upload_outlined), label: Text('Datasets')),
        NavigationRailDestination(icon: Icon(Icons.fact_check_outlined), label: Text('Evaluations')),
      ],
    );
  }
}