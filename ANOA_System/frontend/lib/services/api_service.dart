import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Mengirim data ke endpoint /analyze di backend FastAPI.
  static Future<String> analyze({
    required String data,
    required String mode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'data': data, 'mode': mode}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['message']?.toString() ?? body.toString();
      } else {
        return 'Server error ${response.statusCode}: ${response.reasonPhrase}';
      }
    } catch (e) {
      return '⚠️ Tidak dapat terhubung ke backend ANOA.\n'
          'Pastikan server berjalan: uvicorn main:app --reload\n'
          'URL: $baseUrl\n\nDetail: $e';
    }
  }

  /// Cek apakah backend aktif.
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
