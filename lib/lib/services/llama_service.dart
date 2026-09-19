import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class LlamaService {
  final http.Client _client;
  final String _baseUrl;

  LlamaService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'http://10.0.2.2:8000/v1';

  Future<String> generate(String prompt, {String? modelPath}) async {
    final modelName = (modelPath != null && modelPath.isNotEmpty)
        ? modelPath.split(Platform.pathSeparator).last
        : 'Llama-3.2-1B-Instruct';

    final candidateUrls = <String>{
      _baseUrl,
      'http://10.0.2.2:8000/v1',
      'http://10.149.241.105:8000/v1',
      'http://169.254.132.136:8000/v1',
    }.toList();

    for (final baseUrl in candidateUrls) {
      try {
        final response = await _client.post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': modelName,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.7,
            'max_tokens': 256,
            'stream': false,
          }),
        );

        if (response.statusCode == 200) {
          final payload = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = payload['choices'] as List<dynamic>? ?? const [];
          if (choices.isEmpty) {
            return '';
          }

          final firstChoice = choices.first as Map<String, dynamic>;
          final message =
              firstChoice['message'] as Map<String, dynamic>? ?? const {};
          final content = message['content'];
          if (content is String && content.isNotEmpty) {
            return content;
          }
          return '';
        }
      } on SocketException {
        // Ignore connection errors and fall through.
      } on http.ClientException {
        // Ignore client errors and fall through.
      } on Exception {
        // Ignore unexpected connection errors and fall through.
      }
    }

    return '';
  }
}
