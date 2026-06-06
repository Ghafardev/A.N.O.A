import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _apiKey = 'anoa-secret-key-123';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-KEY': _apiKey,
      };

  /// Mengirim payload untuk dianalisis oleh Gemini via Lobster Trap DPI
  static Future<String> analyze({required String data, required String mode}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: _headers,
        body: json.encode({'data': data, 'mode': mode}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['result'] ?? 'No response from AI.';
      } else if (response.statusCode == 403) {
        return '🛡️ [AUTH ERROR] Access denied. Invalid API Key.';
      } else {
        return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Connection failed: $e';
    }
  }

  /// Menggenerate YAML Rule berdasarkan prompt user
  static Future<String?> generateYaml({required String prompt}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-yaml'),
        headers: _headers,
        body: json.encode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['yaml_content'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Mengambil statistik terbaru untuk dashboard
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Mengunggah knowledge ke RAG backend
  static Future<bool> uploadKnowledge({required String name, required String content}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/knowledge/upload'),
        headers: _headers,
        body: json.encode({'name': name, 'content': content}),
      );
      return response.statusCode == 200;
      } catch (e) {
      return false;
      }
      }

      /// Menerapkan YAML Rule ke DPI backend
      static Future<bool> applyRule({required String yamlContent}) async {
      try {
      final response = await http.post(
        Uri.parse('$_baseUrl/apply-rule'),
        headers: _headers,
        body: json.encode({'yaml_content': yamlContent}),
      );
      return response.statusCode == 200;
      } catch (e) {
      return false;
      }
      }
      }