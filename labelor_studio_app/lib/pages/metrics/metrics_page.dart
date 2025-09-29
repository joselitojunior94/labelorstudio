
import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/glass_card.dart';
import 'package:labelor_studio_app/pages/shared/page_body.dart';
import 'package:labelor_studio_app/service/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key, required this.evalId});
  final int evalId;
  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  Map<String, dynamic>? metrics;
  bool loading = true;
  String? err;

  Future<Api> _api() async {
    final sp = await SharedPreferences.getInstance();
    return Api(sp.getString('access')!);
  }

  Future<void> _load() async {
    setState(() { loading = true; err = null; });
    try {
      final api = await _api();
      metrics = await api.metrics(widget.evalId);
    } catch (e) {
      err = '$e';
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metrics')),
      body: PageBody(
        child: metrics == null
            ? (loading ? const LinearProgressIndicator() : Text(err ?? 'No data'))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Itens usados: ${metrics!['items_used']}'),
                const SizedBox(height: 8),
                const Text('Pares (Cohen’s κ):', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (_, i) {
                      final p = (metrics!['pairs'] as List)[i] as Map<String, dynamic>;
                      return GlassCard(
                        child: ListTile(
                          title: Text('Juízes ${p['judges']}'),
                          subtitle: Text('κ = ${p['cohen_kappa']}'),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: (metrics!['pairs'] as List).length,
                  ),
                ),
                Row(children: [
                  OutlinedButton(onPressed: _load, child: const Text('To update')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      try {
                        final api = await _api();
                        await api.closeEval(widget.evalId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Closed Evaluation')));
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: const Text('Close Evaluation'),
                  ),
                ]),
              ]),
      ),
    );
  }
}