import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:local_llama/lib/services/llama_service.dart';

class _EmptyResponseClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = jsonEncode({
      'choices': [],
    });

    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test('returns empty string instead of showing a failed-generation message', () async {
    final service = LlamaService(
      client: _EmptyResponseClient(),
      baseUrl: 'http://example.com/v1',
    );

    final result = await service.generate('hello');

    expect(result, isEmpty);
  });
}
