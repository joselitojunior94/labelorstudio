import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/glass_card.dart';
import 'package:labelor_studio_app/components/gradient_background.dart';
import 'package:labelor_studio_app/components/section.dart';
import 'package:labelor_studio_app/pages/shared/page_body.dart';
import 'package:labelor_studio_app/service/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key, required this.evalId});
  final int evalId;
  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  Map<String, dynamic>? evaluation;
  Map<String, dynamic>? dataset;    
  List items = [];
  bool loading = true;
  String? err;
  int page = 1;
  final int pageSize = 25;

  Future<Api> _api() async {
    final sp = await SharedPreferences.getInstance();
    return Api(sp.getString('access')!);
  }

  List<Map<String, dynamic>> get _columns {
    final cols = (dataset?['columns'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return cols;
  }

  Future<void> _load() async {
    setState(() { loading = true; err = null; });
    try {
      final api = await _api();

      evaluation ??= await api.getEvaluation(widget.evalId);


      final datasetId = (evaluation!['dataset'] as num).toInt();
      dataset ??= await api.getDataset(datasetId);

      final res = await api.items(widget.evalId, page: page, pageSize: pageSize);
      items = res['results'] as List;
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

  Future<void> _suggest(Map<String, dynamic> item) async {
  try {
    final api = await _api();
    final pair = _extractTitleBody(item['data'] as Map);
    final s = await api.geminiSuggestSimple(title: pair['title']!, body: pair['body']!);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sugestão (Gemini)'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.label_outline),
                const SizedBox(width: 8),
                Text('${s['label'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              if ((s['reason'] ?? '').toString().isNotEmpty) ...[
                const Text('Reason:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SelectableText('${s['reason']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
  }
}


  Map<String, String> _extractTitleBody(Map dataRaw) {
    final data = dataRaw.cast<String, dynamic>();

    String title = '';
    String body  = '';

    
    const titleKeys = ['title', 'subject', 'headline', 'summary', 'titulo', 'assunto'];
    const bodyKeys  = ['body', 'description', 'text', 'content', 'message', 'descricao', 'texto'];

    for (final k in titleKeys) { if (data.containsKey(k)) { title = '${data[k]}'; break; } }
    for (final k in bodyKeys)  { if (data.containsKey(k)) { body  = '${data[k]}'; break; } }

  
    if (title.isEmpty || body.isEmpty) {
      final roles = <String, String>{};
      for (final c in _columns) {
        final name = (c['mapped_name'] ?? c['name_in_file']) as String;
        final role = (c['role'] ?? 'FEATURE') as String;
        roles[name] = role; 
      }

    
      if (body.isEmpty) {
        final textFields = data.entries.where((e) => (roles[e.key] ?? 'FEATURE') == 'TEXT').map((e) => '${e.value}').toList();
        if (textFields.isNotEmpty) {
          body = textFields.take(2).join('\n\n'); 
        }
      }

      if (title.isEmpty) {
        final idKey = data.keys.firstWhere(
          (k) => (roles[k] ?? '') == 'ID',
          orElse: () => data.keys.first,
        );
        title = 'Item ${data[idKey] ?? ''}'.trim();
      }
    }

  
    if (title.trim().isEmpty)  title = 'Item';
    if (body.trim().isEmpty)   body  = title; 

    return {'title': title, 'body': body};
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Itens — Eval ${widget.evalId}')),
      body: PageBody(
        child: Column(children: [
          if (loading) const LinearProgressIndicator(),
          if (err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(err!, style: const TextStyle(color: Colors.red))),
          Expanded(
            child: ListView.separated(
              itemBuilder: (_, i) {
                final it = items[i] as Map<String, dynamic>;
                return GlassCard(
                  child: ListTile(
                    title: Text('Item #${it['row_index']}'),
                    subtitle: Text(_short(it['data'])),
                    trailing: Wrap(spacing: 8, children: [
                      IconButton(
                        tooltip: 'View',
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => _openDetail(it),
                      ),
                      IconButton(
                        tooltip: 'AI suggestion',
                        icon: const Icon(Icons.auto_awesome),
                        onPressed: () => _suggest(it),
                      ),
                      IconButton(
                        tooltip: 'Judge',
                        icon: const Icon(Icons.gavel_outlined),
                        onPressed: () => _openJudge(it),
                      ),
                    ]),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: items.length,
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            OutlinedButton(onPressed: page > 1 ? () { setState(() { page--; _load(); }); } : null, child: const Text('Previous')),
            Text('Page $page'),
            OutlinedButton(onPressed: () { setState(() { page++; _load(); }); }, child: const Text('Next')),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _openDetail(Map<String, dynamic> item) {
    final data = (item['data'] as Map).cast<String, dynamic>();

    final roles = <String, String>{}; 
    for (final c in _columns) {
      final name = (c['mapped_name'] ?? c['name_in_file']) as String;
      final role = (c['role'] ?? 'FEATURE') as String;
      roles[name] = role; 
    }

    Map<String, dynamic> pickByRole(String role) {
      final out = <String, dynamic>{};
      data.forEach((k, v) {
        final r = roles[k] ?? 'FEATURE';
        if (r == role) out[k] = v;
      });
      return out;
    }

    final idMeta   = pickByRole('ID');
    final texts    = pickByRole('TEXT');
    final features = pickByRole('FEATURE');
    final labels   = pickByRole('LABEL');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 700),
          child: GradientBackground(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Text('Item #${item['row_index']}', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Section(title: 'ID / Meta', child: _kvTable(idMeta.isEmpty ? {'row_index': item['row_index']} : idMeta)),
                      const SizedBox(height: 12),
                      if (texts.isNotEmpty)
                        Section(title: 'Text', child: _textTable(texts)),
                      if (features.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Section(title: 'Features', child: _kvTable(features)),
                      ],
                      if (labels.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Section(title: 'Existing labels', child: _kvTable(labels)),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () { Navigator.pop(context); _openJudge(item); },
                    icon: const Icon(Icons.gavel_outlined),
                    label: const Text('Judge this item'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kvTable(Map<String, dynamic> map) {
    final entries = map.entries.toList();
    return GlassCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Field', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: entries.map((e) {
            return DataRow(cells: [
              DataCell(Text(e.key)),
              DataCell(SizedBox(width: 600, child: SelectableText('${e.value}'))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _textTable(Map<String, dynamic> map) {
    final entries = map.entries.toList();
    return Column(
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                SelectableText('${e.value}'),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openJudge(Map<String, dynamic> item) async {
    final value = TextEditingController();
    final conf = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit judgment'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: value, decoration: const InputDecoration(labelText: 'Label/Value')),
            TextField(controller: conf, decoration: const InputDecoration(labelText: 'Confidence (0–1)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                final api = await _api();
                await api.judgment(widget.evalId, (item['id'] as num).toInt(), value: value.text, confidence: double.tryParse(conf.text));
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judgment sent')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  String _short(Map<String, dynamic> data) {
    final s = data.entries.take(3).map((e) => '${e.key}: ${e.value}').join(' | ');
    return s.length > 140 ? '${s.substring(0, 140)}…' : s;
  }
}