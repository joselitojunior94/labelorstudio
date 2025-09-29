import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/glass_card.dart';
import 'package:labelor_studio_app/pages/items/items_page.dart';
import 'package:labelor_studio_app/pages/metrics/metrics_page.dart';
import 'package:labelor_studio_app/pages/results/results_page.dart';
import 'package:labelor_studio_app/pages/shared/page_container.dart';
import 'package:labelor_studio_app/service/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';


class EvaluationsPage extends StatefulWidget {
  const EvaluationsPage({super.key});
  @override
  State<EvaluationsPage> createState() => _EvaluationsPageState();
}

class _EvaluationsPageState extends State<EvaluationsPage> {
  List evals = [];
  bool loading = true;
  String? err;

  Future<Api> _api() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('access');
    if (t == null) throw Exception('No token');
    return Api(t);
  }

  Future<void> _load() async {
    setState(() { loading = true; err = null; });
    try {
      final api = await _api();
      evals = await api.evals();
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
    return PageContainer(
      title: 'Evaluations',
      subtitle: 'Manage assessments, open items, metrics, and results.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (loading) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
        Expanded(
          child: ListView.separated(
            itemBuilder: (_, i) {
              final e = evals[i] as Map<String, dynamic>;
              return GlassCard(
                child: ListTile(
                  title: Text(e['name']),
                  subtitle: Text('Dataset ${e['dataset']} · Owner ${e['owner']['username']} · Status ${e['status']}'),
                  trailing: Wrap(spacing: 8, children: [
                    IconButton(
                      tooltip: 'Items',
                      icon: const Icon(Icons.list_alt),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemsPage(evalId: e['id'] as int))),
                    ),
                    IconButton(
                      tooltip: 'Metrics',
                      icon: const Icon(Icons.analytics_outlined),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MetricsPage(evalId: e['id'] as int))),
                    ),
                    IconButton(
                      tooltip: 'Results',
                      icon: const Icon(Icons.summarize_outlined),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsPage(evalId: e['id'] as int))),
                    ),
                  ]),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: evals.length,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ),
      ]),
    );
  }
}