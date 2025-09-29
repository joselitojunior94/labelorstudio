import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/glass_card.dart';

class KV extends StatelessWidget {
  final String k;
  final String v;

  const KV(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: RichText(
          text: TextSpan(style: DefaultTextStyle.of(context).style, children: [
            TextSpan(text: '$k: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: v),
          ]),
        ),
      ),
    );
  }
}