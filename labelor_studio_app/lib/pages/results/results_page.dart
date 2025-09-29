import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/glass_card.dart';
import 'package:labelor_studio_app/pages/shared/page_body.dart';
import 'package:labelor_studio_app/service/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key, required this.evalId});
  final int evalId;
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  Map<String, dynamic>? results;
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
      results = await api.results(widget.evalId);
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
    final jsonUrl = '$kApiBaseUrl/api/evaluations/${widget.evalId}/export/json/';
    final csvUrl  = '$kApiBaseUrl/api/evaluations/${widget.evalId}/export/csv/';

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: PageBody(
        child: results == null
            ? (loading ? const LinearProgressIndicator() : Text(err ?? 'No data'))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (_, i) {
                      final r = (results!['results'] as List)[i] as Map<String, dynamic>;
                      return GlassCard(
                        child: ListTile(
                          title: Text('Item ${r['item_id']} — Majority: ${r['majority']}'),
                          subtitle: Text('Counts: ${r['counts']}'),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: (results!['results'] as List).length,
                  ),
                ),
                Row(children: [
                  OutlinedButton.icon(
                    onPressed: () => _open(jsonUrl),
                    icon: const Icon(Icons.data_object),
                    label: const Text('Export JSON'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _open(csvUrl),
                    icon: const Icon(Icons.table_view),
                    label: const Text('Export CSV'),
                  ),
                ]),
              ]),
      ),
    );
  }

  void _open(String url) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open in browser: $url')));
  }
}