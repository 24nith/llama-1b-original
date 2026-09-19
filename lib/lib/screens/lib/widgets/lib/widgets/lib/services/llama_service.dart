import 'dart:convert';
import 'package:http/http.dart' as http;

class LlamaService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<String> generate(String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'Llama-3.2-1B-Instruct',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 256,
        'stream': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'The llama server connection was closed. Please make sure the host server is running on http://10.0.2.2:8000 or http://10.149.241.105:8000.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>? ?? const [];
    if (choices.isEmpty) {
      throw Exception('The llama server returned no completion.');
    }

    final firstChoice = choices.first as Map<String, dynamic>;
    final message = firstChoice['message'] as Map<String, dynamic>? ?? const {};
    final content = message['content'];
    return content is String && content.isNotEmpty ? content : 'No response generated.';
  }
}