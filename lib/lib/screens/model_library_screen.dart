import 'dart:async';

import 'package:flutter/material.dart';

import '../services/model_manager.dart';

class ModelLibraryScreen extends StatefulWidget {
  final ModelManager manager;
  final LocalModel? activeModel;

  const ModelLibraryScreen({
    super.key,
    required this.manager,
    this.activeModel,
  });

  @override
  State<ModelLibraryScreen> createState() => _ModelLibraryScreenState();
}

class _ModelLibraryScreenState extends State<ModelLibraryScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<HuggingFaceModel> _models = const [];
  List<LocalModel> _localModels = const [];
  bool _loading = true;
  String? _error;
  String? _downloadingModel;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () => _loadModels(query));
  }

  Future<void> _loadModels([String query = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final models = await widget.manager.search(query);
      final localModels = await widget.manager.localModels();
      if (mounted) {
        setState(() {
          _models = models;
          _localModels = localModels;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(HuggingFaceModel model) async {
    try {
      final files = await widget.manager.filesFor(model.id);
      if (!mounted || files.isEmpty) {
        if (mounted) setState(() => _error = 'No GGUF files found for this model.');
        return;
      }

      final selectedFile = _preferredFile(files);

      setState(() {
        _downloadingModel = model.id;
        _progress = 0;
        _error = null;
      });
      final downloaded = await widget.manager.download(model.id, selectedFile, (progress) {
        if (mounted) setState(() => _progress = progress);
      });
      if (mounted) Navigator.pop(context, downloaded);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _downloadingModel = null;
          _progress = null;
        });
      }
    }
  }

  String _preferredFile(List<String> files) {
    final preferred = files.where((file) {
      final name = file.toLowerCase();
      return name.contains('q4_k_m') || name.contains('q4_km');
    });
    return preferred.isNotEmpty ? preferred.first : files.first;
  }

  bool _isDownloaded(HuggingFaceModel model) {
    return _localModels.any((local) => local.name.startsWith(model.displayName));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        foregroundColor: const Color(0xFF17202A),
        elevation: 0,
        title: const Text(
          'Models',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Model settings',
            onPressed: _loading ? null : () => _loadModels(_searchController.text),
            icon: const Icon(Icons.settings_outlined, size: 28),
          ),
          const SizedBox(width: 10),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        backgroundColor: const Color(0xFFF8F9FD),
        indicatorColor: const Color(0xFFD6E9FF),
        onDestinationSelected: (index) {
          if (index == 0) Navigator.pop(context);
          if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Server settings are coming soon.')),
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Models'),
          NavigationDestination(icon: Icon(Icons.cloud_outlined), label: 'Server'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadModels(_searchController.text),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 30),
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _loadModels,
              style: const TextStyle(color: Color(0xFF26313C), fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Search models...',
                hintStyle: const TextStyle(color: Color(0xFF58626D), fontSize: 19),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF46515D), size: 29),
                suffixIcon: IconButton(
                  onPressed: () => _loadModels(_searchController.text),
                  icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF46515D)),
                ),
                filled: true,
                fillColor: const Color(0xFFE4E5E9),
                contentPadding: const EdgeInsets.symmetric(vertical: 21),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryChip('🧠  Qwen', 'qwen'),
                  _categoryChip('🦙  Llama', 'llama'),
                  _categoryChip('💎  Gemma', 'gemma'),
                  _categoryChip('🎯  Phi', 'phi'),
                ],
              ),
            ),
            if (_localModels.isEmpty) ...[
              const SizedBox(height: 24),
              _buildQuickStart(),
            ],
            const SizedBox(height: 30),
            if (_localModels.isNotEmpty) ...[
              _sectionTitle(Icons.inventory_2_outlined, 'Your models', 'Installed on this phone'),
              const SizedBox(height: 12),
              ..._localModels.map((model) => _installedCard(model)),
              const SizedBox(height: 24),
            ],
            _sectionTitle(Icons.explore_outlined, 'Browse catalog', 'Curated GGUF models • one-tap download'),
            const SizedBox(height: 12),
          if (_progress != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  LinearProgressIndicator(value: _progress, color: const Color(0xFF4F8CC9)),
                  const SizedBox(height: 4),
                  Text('Downloading ${(_progress! * 100).round()}%', style: const TextStyle(color: Color(0xFF46515D))),
                ],
              ),
            ),
          if (_error != null && _models.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!.replaceFirst('Exception: ', ''),
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
            ),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
          else if (_models.isEmpty)
            const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No models found.')))
          else
            ..._models.map((model) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ModelTile(
                    model: model,
                    downloaded: _isDownloaded(model),
                    downloading: _downloadingModel == model.id,
                    onDownload: () => _download(model),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String query) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF424B55))),
        backgroundColor: const Color(0xFFE7E8EC),
        side: const BorderSide(color: Color(0xFFD0D2D7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        onPressed: () {
          _searchController.text = query;
          _loadModels(query);
        },
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: const Color(0xFFD7EEFF), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF11608B)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF17202A))),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF58626D))),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE0EDFF), Color(0xFFF0E4FF)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC8D9F4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick start', style: TextStyle(color: Color(0xFF276184), fontWeight: FontWeight.w700, fontSize: 16)),
          SizedBox(height: 14),
          Text('One step left to start chat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF17202A))),
          SizedBox(height: 10),
          Text('Download an installed model below, then open Chat to begin.', style: TextStyle(fontSize: 16, height: 1.4, color: Color(0xFF46515D))),
        ],
      ),
    );
  }

  Widget _installedCard(LocalModel model) {
    return InkWell(
      onTap: () => Navigator.pop(context, model),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE1E3E8))),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Color(0xFFEFF0F4), child: Icon(Icons.memory_rounded, color: Color(0xFF303943))),
            const SizedBox(width: 14),
            Expanded(child: Text(model.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF17202A)))),
            if (model.path == widget.activeModel?.path) const Icon(Icons.check_circle, color: Color(0xFF2D83B9)),
          ],
        ),
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final HuggingFaceModel model;
  final bool downloaded;
  final bool downloading;
  final VoidCallback onDownload;

  const _ModelTile({
    required this.model,
    required this.downloaded,
    required this.downloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9DCE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _colorForModel(model),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(_iconForModel(model), size: 38, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _titleForModel(model),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF17202A)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: downloaded || downloading ? null : onDownload,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD6E9FF),
                  foregroundColor: const Color(0xFF354D66),
                  disabledBackgroundColor: const Color(0xFFE0E3E8),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: downloading
                    ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(downloaded ? Icons.check : Icons.download_rounded, size: 19),
                label: Text(downloaded ? 'Added' : 'Get', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _descriptionForModel(model),
            style: const TextStyle(fontSize: 16, height: 1.35, color: Color(0xFF46515D)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _metaPill(Icons.tune_rounded, _parameterLabel(model)),
              _metaPill(Icons.cloud_download_outlined, _downloadLabel(model)),
              _metaPill(Icons.layers_outlined, 'Q4_K_M'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4E5965)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Color(0xFF35404B), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _titleForModel(HuggingFaceModel model) {
    final name = model.displayName.replaceAll('-', ' ');
    return name.length > 34 ? name.substring(0, 34) : name;
  }

  String _descriptionForModel(HuggingFaceModel model) {
    final name = model.displayName.toLowerCase();
    if (name.contains('gemma')) return 'Compact and fast. A practical model for everyday phone tasks.';
    if (name.contains('qwen')) return 'Tiny and efficient. Good for testing and lightweight chat.';
    if (name.contains('llama')) return 'A balanced local assistant model for private conversations.';
    return 'A downloadable GGUF model ready for local use on your phone.';
  }

  String _parameterLabel(HuggingFaceModel model) {
    final match = RegExp(r'\d+(?:\.\d+)?[bBmM]').firstMatch(model.displayName);
    return match?.group(0)?.toUpperCase() ?? 'GGUF';
  }

  String _downloadLabel(HuggingFaceModel model) {
    if (model.downloads >= 1000000) return '${(model.downloads / 1000000).toStringAsFixed(1)}M';
    if (model.downloads >= 1000) return '${(model.downloads / 1000).toStringAsFixed(0)}K';
    return '${model.downloads}';
  }

  Color _colorForModel(HuggingFaceModel model) {
    final name = model.displayName.toLowerCase();
    if (name.contains('qwen')) return const Color(0xFF7B3FE4);
    if (name.contains('llama')) return const Color(0xFFF2A51A);
    if (name.contains('gemma')) return const Color(0xFF26B6DD);
    return const Color(0xFF4D9CD2);
  }

  IconData _iconForModel(HuggingFaceModel model) {
    final name = model.displayName.toLowerCase();
    if (name.contains('qwen')) return Icons.auto_awesome;
    if (name.contains('llama')) return Icons.pets_outlined;
    if (name.contains('gemma')) return Icons.smart_toy_outlined;
    return Icons.memory_rounded;
  }
}