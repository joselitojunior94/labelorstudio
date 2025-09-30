import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const String kApiBaseUrl = "http://127.0.0.1:8000";

class Api {
  Api(this.t);
  final String t;
  Map<String, String> _h([Map<String, String>? x]) => {'Authorization': 'Bearer $t', ...?x};

  Future<Map<String, dynamic>> getEvaluation(int id) async {
    final r = await http.get(Uri.parse('$kApiBaseUrl/api/evaluations/$id/'), headers: _h());
    if (r.statusCode != 200) throw Exception('get eval: ${r.statusCode} ${r.body}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDataset(int id) async {
    final r = await http.get(Uri.parse('$kApiBaseUrl/api/datasets/$id/'), headers: _h());
    if (r.statusCode != 200) throw Exception('get dataset: ${r.statusCode} ${r.body}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }


  Future<Map<String, dynamic>> geminiSuggestSimple({
    required String title,
    required String body,
  }) async {
    final r = await http.post(
      Uri.parse('$kApiBaseUrl/api/gemini/suggest/'),
      headers: _h({'Content-Type': 'application/json'}),
      body: jsonEncode({'title': title, 'body': body}),
    );
    if (r.statusCode != 200) {
      throw Exception('geminiSuggest: ${r.statusCode} ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> upload({
    required Uint8List bytes,
    required String filename,
    required Map<String, dynamic> meta,
    int? datasetId,
  }) async {
    final uri = Uri.parse(datasetId == null
        ? '$kApiBaseUrl/api/datasets/upload-csv/'
        : '$kApiBaseUrl/api/datasets/$datasetId/upload-csv/');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_h());
    req.fields['meta'] = jsonEncode(meta);
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: MediaType('text', 'csv')));
    final s = await req.send();
    final r = await http.Response.fromStream(s);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('upload: ${r.statusCode} ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> saveMap(int ds, int ver, List<Map<String, dynamic>> cols) async {
    final r = await http.post(
      Uri.parse('$kApiBaseUrl/api/datasets/$ds/versions/$ver/mapping/'),
      headers: _h({'Content-Type': 'application/json'}),
      body: jsonEncode({'columns': cols}),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('mapping: ${r.statusCode} ${r.body}');
    }
  }

  Future<List> evals() async {
    final r = await http.get(Uri.parse('$kApiBaseUrl/api/evaluations/'), headers: _h());
    if (r.statusCode != 200) throw Exception('evals: ${r.statusCode}');
    return jsonDecode(r.body) as List;
  }

  Future<Map<String, dynamic>> createEval(String name, int datasetId,
      {List<int>? judges, List<int>? reviewers, List<int>? viewers}) async {
    final body = {
      'name': name,
      'dataset': datasetId,
      'judges': judges ?? [],
      'reviewers': reviewers ?? [],
      'viewers': viewers ?? [],
    };
    final r = await http.post(
      Uri.parse('$kApiBaseUrl/api/evaluations/'),
      headers: _h({'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('create eval: ${r.statusCode} ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> items(int evalId, {int page = 1, int pageSize = 50}) async {
    final r = await http.get(
      Uri.parse('$kApiBaseUrl/api/evaluations/$evalId/items/?page=$page&page_size=$pageSize'),
      headers: _h(),
    );
    if (r.statusCode != 200) throw Exception('items: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> judgment(int evalId, int itemId, {required String value, double? confidence}) async {
    final r = await http.post(
      Uri.parse('$kApiBaseUrl/api/evaluations/$evalId/items/$itemId/judgments/'),
      headers: _h({'Content-Type': 'application/json'}),
      body: jsonEncode({'value': value, 'confidence': confidence}),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('judgment: ${r.statusCode} ${r.body}');
  }

  Future<void> review(int evalId, int itemId, {String? notes, String? acceptedValue}) async {
    final r = await http.post(
      Uri.parse('$kApiBaseUrl/api/evaluations/$evalId/items/$itemId/reviews/'),
      headers: _h({'Content-Type': 'application/json'}),
      body: jsonEncode({'notes': notes ?? '', 'accepted_value': acceptedValue ?? ''}),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('review: ${r.statusCode} ${r.body}');
  }

  Future<Map<String, dynamic>> metrics(int evalId) async {
    final r = await http.get(Uri.parse('$kApiBaseUrl/api/evaluations/$evalId/metrics/'), headers: _h());
    if (r.statusCode != 200) throw Exception('metrics: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> results(int evalId) async {
    final r = await http.get(Uri.parse('$kApiBaseUrl/api/evaluations/$evalId/results/'), headers: _h());
    if (r.statusCode != 200) throw Exception('results: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> closeEval(int evalId) async {
    final r = await http.post(Uri.parse('$kApiBaseUrl/api/evaluations/$evalId/close/'), headers: _h());
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('close: ${r.statusCode} ${r.body}');
  }
}