import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class HuggingFaceModel {
  final String id;
  final int downloads;
  final List<String> ggufFiles;

  const HuggingFaceModel({
    required this.id,
    required this.downloads,
    required this.ggufFiles,
  });

  String get displayName => id.split('/').last;
}

class LocalModel {
  final String name;
  final String path;

  const LocalModel({required this.name, required this.path});
}

class ModelManager {
  static const _apiBase = 'https://huggingface.co/api';
  static const _offlineCatalog = <HuggingFaceModel>[
    HuggingFaceModel(id: 'bartowski/Llama-3.2-1B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Llama-3.2-3B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Llama-3.1-8B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/gemma-3-270m-it-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/gemma-3-1b-it-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/gemma-3-4b-it-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/gemma-2-2b-it-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen2.5-0.5B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen2.5-1.5B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen2.5-3B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen2.5-7B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen3-0.6B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen3-1.7B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen3-4B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen3-8B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen2.5-Coder-0.5B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen2.5-Coder-3B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen3-Coder-30B-A3B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/SmolLM2-135M-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/SmolLM2-360M-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/SmolLM2-1.7B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/TinyLlama-1.1B-Chat-v1.0-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Phi-3.5-mini-instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Phi-4-mini-instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Phi-4-mini-reasoning-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/StableLM-2-1.6B-Chat-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/MobileLLM-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/MobileLLM-125M-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/MobileLLM-350M-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/MobileLLM-600M-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/MobileLLM-1.5B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/OpenELM-270M-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/OpenELM-450M-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/OpenELM-1.1B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/OpenELM-3B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/TinyChat-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/TinyChat2-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/MiniCPM-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/MiniCPM-2B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/MiniCPM3-4B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/DeepSeek-R1-Distill-Llama-8B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Granite-3.1-2B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Granite-3.2-2B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Granite-4.0-Micro-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/OLMo-1B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/OLMo-1B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/RWKV-6-1.6B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/RWKV-6-3B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Bielik-1.5B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/EuroLLM-1.7B-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/SmolVLM-256M-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/SmolVLM-500M-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen2-VL-2B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/Qwen2.5-VL-3B-Instruct-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/gemma-3n-E2B-it-GGUF', downloads: 0, ggufFiles: []),
    HuggingFaceModel(id: 'bartowski/gemma-3n-E4B-it-GGUF', downloads: 0, ggufFiles: []),
  ];

  Future<List<HuggingFaceModel>> search(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final parameters = <String, String>{
      'filter': 'gguf',
      'sort': 'downloads',
      'direction': '-1',
      'limit': '50',
    };
    if (normalizedQuery.isNotEmpty) parameters['search'] = normalizedQuery;
    final uri = Uri.parse('$_apiBase/models').replace(queryParameters: parameters);
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Hugging Face search failed (${response.statusCode})');
      }
      final results = jsonDecode(response.body) as List<dynamic>;
      final remoteResults = results.map((item) {
        final model = item as Map<String, dynamic>;
        return HuggingFaceModel(
          id: model['id'] as String,
          downloads: model['downloads'] as int? ?? 0,
          ggufFiles: const [],
        );
      }).toList();
      return _relevantResults(normalizedQuery, remoteResults);
    } on SocketException catch (_) {
      return _offlineResults(query);
    } on TimeoutException catch (_) {
      return _offlineResults(query);
    } on http.ClientException catch (_) {
      return _offlineResults(query);
    } on FormatException catch (_) {
      return _offlineResults(query);
    } on Exception catch (_) {
      return _offlineResults(query);
    }
  }

  List<HuggingFaceModel> _offlineResults(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return _offlineCatalog;
    return _offlineCatalog
        .where((model) => model.id.toLowerCase().contains(normalizedQuery))
        .toList();
  }

  List<HuggingFaceModel> _relevantResults(
    String query,
    List<HuggingFaceModel> remoteResults,
  ) {
    final curatedResults = _offlineResults(query);
    final seenIds = <String>{};
    final combinedResults = <HuggingFaceModel>[];

    void addUnique(HuggingFaceModel model) {
      if (seenIds.add(model.id)) combinedResults.add(model);
    }

    for (final model in curatedResults) {
      addUnique(model);
    }
    for (final model in _rankResults(query, remoteResults)) {
      addUnique(model);
    }
    return combinedResults;
  }

  List<HuggingFaceModel> _rankResults(
    String query,
    List<HuggingFaceModel> results,
  ) {
    if (query.isEmpty) return results;
    final rankedResults = [...results];
    rankedResults.sort((first, second) {
      final firstScore = _matchScore(query, first);
      final secondScore = _matchScore(query, second);
      return secondScore.compareTo(firstScore);
    });
    return rankedResults;
  }

  int _matchScore(String query, HuggingFaceModel model) {
    final name = model.displayName.toLowerCase();
    final id = model.id.toLowerCase();
    if (name == query) return 3;
    if (name.startsWith(query)) return 2;
    if (name.contains(query) || id.contains(query)) return 1;
    return 0;
  }

  Future<List<String>> filesFor(String modelId) async {
    late final http.Response response;
    try {
      response = await http
          .get(Uri.parse('$_apiBase/models/$modelId'))
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('No internet connection. Connect to Wi-Fi or mobile data and try again.');
    } on TimeoutException {
      throw Exception('Model service timed out. Check your internet connection and try again.');
    } on http.ClientException {
      throw Exception('Could not connect to the model service.');
    }
    if (response.statusCode != 200) {
      throw Exception('This model is unavailable right now (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final siblings = data['siblings'] as List<dynamic>? ?? const [];
    return siblings
        .map((file) => (file as Map<String, dynamic>)['rfilename'] as String?)
        .whereType<String>()
        .where((file) => file.toLowerCase().endsWith('.gguf'))
        .toList();
  }

  Future<LocalModel> download(
    String modelId,
    String fileName,
    void Function(double progress) onProgress,
  ) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/models');
    await directory.create(recursive: true);
    final safeName = fileName.split('/').last;
    final target = File('${directory.path}/$safeName');
    final request = http.Request(
      'GET',
      Uri.parse('https://huggingface.co/$modelId/resolve/main/$fileName'),
    );
    final client = http.Client();
    try {
      final response = await client.send(request).timeout(const Duration(minutes: 30));
      if (response.statusCode != 200) {
        throw Exception('Model download failed (${response.statusCode}).');
      }
      final output = target.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        output.add(chunk);
        received += chunk.length;
        if (response.contentLength != null && response.contentLength! > 0) {
          onProgress(received / response.contentLength!);
        }
      }
      await output.close();
      onProgress(1);
      return LocalModel(name: safeName, path: target.path);
    } on SocketException {
      await _deletePartial(target);
      throw Exception('Download interrupted. Check your internet connection and try again.');
    } on TimeoutException {
      await _deletePartial(target);
      throw Exception('Download timed out. Try again on a stable connection.');
    } finally {
      client.close();
    }
  }

  Future<void> _deletePartial(File target) async {
    if (await target.exists()) await target.delete();
  }

  Future<List<LocalModel>> localModels() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/models');
    if (!await directory.exists()) return const [];
    final entries = await directory.list().toList();
    return entries
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.gguf'))
        .map((file) => LocalModel(
              name: file.path.split(Platform.pathSeparator).last,
              path: file.path,
            ))
        .toList();
  }
}