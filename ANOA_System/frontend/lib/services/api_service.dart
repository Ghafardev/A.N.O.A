import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ─── Analyze: Purple Team AI ────────────────────────────────────────────────
  static Future<String> analyze({
    required String data,
    required String mode,
    String? context,
  }) async {
    try {
      final body = <String, dynamic>{'data': data, 'mode': mode};
      if (context != null && context.isNotEmpty) {
        body['context'] = context;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['result']?.toString() ?? '(Tidak ada respons dari AI)';
      } else {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        return '⚠️ Server Error ${response.statusCode}: ${err['detail'] ?? response.reasonPhrase}';
      }
    } catch (e) {
      return '⚠️ Tidak dapat terhubung ke backend ANOA.\n'
          'Pastikan server sudah berjalan:\n'
          '  uvicorn main:app --reload\n\n'
          'Backend URL: $baseUrl\nDetail: $e';
    }
  }

  // ─── Generate YAML Rules via Gemini ─────────────────────────────────────────
  static Future<String> generateYaml({required String prompt}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/generate-yaml'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['yaml_content']?.toString() ?? '# (Tidak ada output YAML)';
      } else {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        return '# ⚠️ Error ${response.statusCode}: ${err['detail']}';
      }
    } catch (e) {
      return '# ⚠️ Tidak dapat terhubung ke backend\n# Detail: $e';
    }
  }

  // ─── Health Check ────────────────────────────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
