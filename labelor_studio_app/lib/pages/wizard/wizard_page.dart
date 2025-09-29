import 'dart:convert';
import 'dart:io' as uio;
import 'package:csv/csv.dart' as csv;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/glass_card.dart';
import 'package:labelor_studio_app/components/kv.dart';
import 'package:labelor_studio_app/components/mapping.dart';
import 'package:labelor_studio_app/data_structures/column_role.dart';
import 'package:labelor_studio_app/data_structures/column_spec.dart';
import 'package:labelor_studio_app/data_structures/selected_csv.dart';
import 'package:labelor_studio_app/data_structures/upload_mode.dart';
import 'package:labelor_studio_app/pages/shared/page_container.dart';
import 'package:labelor_studio_app/service/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WizardPage extends StatefulWidget {
  const WizardPage({super.key});
  @override
  State<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends State<WizardPage> {
  UploadMode mode = UploadMode.single;
  String datasetName = 'Meu Dataset';
  String delimiter = ',';
  String encoding = 'UTF-8';

  String? fileName;
  Uint8List? fileBytes;
  final List<SelectedCsv> batch = [];

  List<String> headers = [];
  List<List<String>> rows = [];
  List<ColumnSpec> columns = [];

  bool busy = false;
  String? info;
  String? err;

  int? lastDatasetId;
  int? lastVersion;

  Future<Api> _api() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('access');
    if (t == null) throw Exception('No token');
    return Api(t);
    }

  List<List<String>> _strictParse(String text, String d) {
    final conv = csv.CsvToListConverter(
      fieldDelimiter: d == '\t' ? '\t' : d,
      eol: '\n',
      shouldParseNumbers: false,
    );
    final parsed = conv.convert(text);
    if (parsed.isEmpty) return [];
    final raw = parsed.first.map((e) => e.toString()).toList();
    final hdr = <String>[];
    for (int i = 0; i < raw.length; i++) {
      hdr.add(raw[i].trim().isEmpty ? 'col_$i' : raw[i].trim());
    }
    final H = hdr.length;
    final out = <List<String>>[hdr];
    for (final r in parsed.skip(1)) {
      final rr = r.map((e) => e.toString()).toList();
      if (rr.length > H) out.add(rr.sublist(0, H));
      else if (rr.length < H) out.add([...rr, ...List.filled(H - rr.length, '')]);
      else out.add(rr);
    }
    return out;
  }

  String _detectDelimiter(String content) {
    const cands = [',', ';', '\t', '|'];
    final first = content.split('\n').firstWhere((e) => e.trim().isNotEmpty, orElse: () => '');
    int best = -1; String bestD = ',';
    for (final d in cands) {
      final cnt = first.split(d == '\t' ? '\t' : d).length;
      if (cnt > best) { best = cnt; bestD = d; }
    }
    return bestD;
  }

  Future<void> _pickSingle() async {
    setState(() { err = null; info = null; });
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    fileName = f.name;
    fileBytes = f.bytes ?? (f.path != null && !kIsWeb ? await uio.File(f.path!).readAsBytes() : null);
    if (fileBytes == null) { setState(() => err = 'Failed to read file'); return; }
    String text;
    try { text = utf8.decode(fileBytes!); encoding = 'UTF-8'; }
    catch (_) { text = const Latin1Codec().decode(fileBytes!); encoding = 'ISO-8859-1'; }
    delimiter = _detectDelimiter(text);
    final norm = _strictParse(text, delimiter);
    if (norm.isEmpty) { setState(() => err = 'Empty CSV'); return; }
    headers = norm.first;
    rows = norm.skip(1).take(20).toList();
    _initColumns();
    setState(() {});
  }

  Future<void> _pickMulti() async {
    setState(() { err = null; info = null; });
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'], withData: true, allowMultiple: true);
    if (res == null || res.files.isEmpty) return;
    batch.clear();
    List<String>? ref;
    for (final f in res.files) {
      final bytes = f.bytes ?? (f.path != null && !kIsWeb ? await uio.File(f.path!).readAsBytes() : null);
      if (bytes == null) continue;
      String text; try { text = utf8.decode(bytes); } catch (_) { text = const Latin1Codec().decode(bytes); }
      final d = _detectDelimiter(text);
      final norm = _strictParse(text, d);
      if (norm.isEmpty) continue;
      final hdr = norm.first; final data = norm.skip(1).toList();
      ref ??= hdr; final H = ref.length;
      final aligned = [for (final r in data) (r.length > H ? r.sublist(0, H) : (r.length < H ? [...r, ...List.filled(H - r.length, '')] : r))];
      batch.add(SelectedCsv(name: f.name, bytes: bytes, headers: ref, allRows: aligned));
    }
    if (batch.isEmpty) { setState(() => err = 'No valid CSV'); return; }
    headers = List<String>.from(batch.first.headers);
    rows = [];
    for (final b in batch) {
      for (final r in b.allRows) { rows.add(r); if (rows.length >= 20) break; }
      if (rows.length >= 20) break;
    }
    _initColumns();
    setState(() {});
  }

  void _initColumns() {
    columns = [for (final h in headers) ColumnSpec(nameInFile: h, mappedName: h)];
    if (columns.isNotEmpty) columns.first.role = ColumnRole.id;
    final lower = headers.map((e) => e.toLowerCase()).toList();
    for (int i = 0; i < columns.length; i++) {
      final n = lower[i];
      if (n.contains('title') || n.contains('descr') || n.contains('text') || n.contains('message')) {
        columns[i].role = ColumnRole.text;
      }
      if (n == 'label' || n.contains('class') || n.contains('tag')) {
        columns[i].role = ColumnRole.label;
      }
    }
  }

  Uint8List _merge() {
    final d = delimiter == '\t' ? '\t' : delimiter;
    final buf = StringBuffer()..writeln(headers.join(d));
    for (final f in batch) { for (final r in f.allRows) { buf.writeln(r.join(d)); } }
    return Uint8List.fromList(utf8.encode(buf.toString()));
  }

  Future<Api> _apiOrErr() async {
    try { return await _api(); } catch (e) { setState(() => err = '$e'); rethrow; }
  }

  Future<void> _send() async {
    if (mode == UploadMode.single && fileBytes == null) return;
    setState(() { busy = true; err = null; info = null; });
    try {
      final api = await _apiOrErr();
      final bytes = mode == UploadMode.single ? fileBytes! : _merge();
      final meta = {
        'delimiter': delimiter,
        'encoding': mode == UploadMode.single ? encoding : 'UTF-8',
        'dataset_name': datasetName,
        'headers_present': true,
        'mode': mode.name,
        'source_count': mode == UploadMode.single ? 1 : batch.length,
        'merge_mode': 'append',
        'merged_client_side': mode == UploadMode.multi,
      };
      final resp = await api.upload(bytes: bytes, filename: mode == UploadMode.single ? (fileName ?? 'data.csv') : 'merged_${batch.length}.csv', meta: meta);
      lastDatasetId = (resp['dataset_id'] as num).toInt();
      lastVersion = (resp['version'] as num).toInt();
      await api.saveMap(lastDatasetId!, lastVersion!, [for (final c in columns) c.toJson()]);
      info = 'Dataset $lastDatasetId (v$lastVersion) sent and mapped!';
      await _promptCreateEval(context, api, lastDatasetId!);
    } catch (e) {
      err = '$e';
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _promptCreateEval(BuildContext ctx, Api api, int datasetId) async {
    final name = TextEditingController(text: 'Evaluation ${DateTime.now().toIso8601String().substring(0, 19)}');
    final judges = TextEditingController();
    final reviewers = TextEditingController();
    final viewers = TextEditingController();
    List<int> ids(String s) => s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).map(int.parse).toList();
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Create Evaluation now?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(alignment: Alignment.centerLeft, child: Text('Dataset ID: $datasetId', style: const TextStyle(fontWeight: FontWeight.w700))),
            const SizedBox(height: 8),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: judges, decoration: const InputDecoration(labelText: 'Judges (ids, vírgula)')),
            TextField(controller: reviewers, decoration: const InputDecoration(labelText: 'Reviewers (ids)')),
            TextField(controller: viewers, decoration: const InputDecoration(labelText: 'Viewers (ids)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final ev = await api.createEval(name.text, datasetId, judges: ids(judges.text), reviewers: ids(reviewers.text), viewers: ids(viewers.text));
        if (!mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Evaluation created: ${ev['id']}')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return PageContainer(
    title: 'Dataset Wizard',
    subtitle: 'Upload CSV(s), preview, map columns and generate an Evaluation.',
    child: Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<UploadMode>(
                      segments: const [
                        ButtonSegment(value: UploadMode.single, label: Text('1 file')),
                        ButtonSegment(value: UploadMode.multi, label: Text('N files')),
                      ],
                      selected: {mode},
                      onSelectionChanged: (s) => setState(() => mode = s.first),
                    ),
                    SizedBox(
                      width: 280,
                      child: TextFormField(
                        initialValue: datasetName,
                        decoration: const InputDecoration(labelText: 'Nome do dataset'),
                        onChanged: (v) => datasetName = v,
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: delimiter,
                        decoration: const InputDecoration(labelText: 'Delimiter'),
                        items: [',', ';', '\t', '|']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e == '\t' ? 'Tab' : e)))
                            .toList(),
                        onChanged: (v) => setState(() => delimiter = v ?? ','),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: encoding,
                        decoration: const InputDecoration(labelText: 'Encoding'),
                        items: ['UTF-8', 'ISO-8859-1', 'Windows-1252']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => encoding = v ?? 'UTF-8'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: InkWell(
                    onTap: mode == UploadMode.single ? _pickSingle : _pickMulti,
                    child: Container(
                      height: 130,
                      alignment: Alignment.center,
                      child: Text(
                        headers.isEmpty
                            ? (mode == UploadMode.single
                                ? 'Click to select one .csv'
                                : 'Click to select multiple .csv files')
                            : (mode == UploadMode.single
                                ? 'File: $fileName'
                                : 'Files: ${batch.length}'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (headers.isNotEmpty) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      KV('Delimiter', delimiter == '\t' ? 'Tab' : delimiter),
                      KV('Encoding', encoding),
                      KV('Header', '1st line only'),
                      if (mode == UploadMode.multi) KV('Files', '${batch.length}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Preview (20 lines)', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  GlassCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal, 
                      child: DataTable(
                        columns: [
                          for (final h in headers)
                            DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.w700)))
                        ],
                        rows: rows
                            .map((r) => DataRow(
                                  cells: [for (final c in r) DataCell(SizedBox(width: 220, child: Text(c)))],
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Column mapping', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Mapping(columns: columns, onChanged: () => setState(() {})),
                  const SizedBox(height: 12),
                  if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
                  if (info != null) Text(info!, style: const TextStyle(color: Colors.green)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _send,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Send and save mapping'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (busy)
          Positioned.fill(
            child: Container(
              color: Colors.white60,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ),
  );
}

}