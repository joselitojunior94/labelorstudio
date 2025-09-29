import 'package:flutter/material.dart';

class ChipComp extends StatelessWidget {
  final IconData icon;
  final String label;

  const ChipComp({required this.icon, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: const Color(0xFF0C6CF2)),
        const SizedBox(width: 6),
        Text(label),
      ]),
    );
  }
}