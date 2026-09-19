import 'package:flutter/material.dart';
import '../services/llama_service.dart';
import '../services/model_manager.dart';
import 'package:local_llama/lib/screens/lib/widgets/chat_bubble.dart';
import 'package:local_llama/lib/screens/lib/widgets/lib/widgets/message_input.dart';
import 'model_library_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final LlamaService _llamaService = LlamaService();
  final ModelManager _modelManager = ModelManager();

  final List<Map<String, String>> _messages = [];

  bool _isGenerating = false;
  LocalModel? _activeModel;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isGenerating) {
      return;
    }

    setState(() {
      _messages.add({
        'role': 'user',
        'message': text,
      });

      _controller.clear();
      _isGenerating = true;
    });

    _scrollToBottom();

    try {
      final response = await _llamaService.generate(
        text,
        modelPath: _activeModel?.path,
      );

      setState(() {
        _messages.add({
          'role': 'assistant',
          'message': response,
        });
      });
    } catch (_) {
      // Ignore server errors and clear the UI state silently.
    }

    setState(() {
      _isGenerating = false;
    });

    _scrollToBottom();
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _chooseModel() async {
    final selected = await Navigator.push<LocalModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ModelLibraryScreen(
          manager: _modelManager,
          activeModel: _activeModel,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _activeModel = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF050A12),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        toolbarHeight: 80,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFF9C6BFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.28),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local Llama',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Llama 3.2 • Offline',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Choose model',
            onPressed: _chooseModel,
            icon: const Icon(Icons.expand_more_rounded, size: 28),
            color: Colors.white70,
          ),
          IconButton(
            tooltip: 'Clear chat',
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_outline, size: 24),
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: const Color(0xFF050A12),
        child: Column(
          children: [
            _buildStatus(),
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        20,
                        16,
                        20,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final item = _messages[index];
                        return ChatBubble(
                          message: item['message']!,
                          isUser: item['role'] == 'user',
                        );
                      },
                    ),
            ),
            if (_isGenerating)
              const Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  bottom: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Local model is thinking...',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            MessageInput(
              controller: _controller,
              onSend: _sendMessage,
              enabled: !_isGenerating,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 9,
            color: Colors.greenAccent,
          ),
          SizedBox(width: 8),
          Text(
            _activeModel == null
                ? 'Choose a model to begin'
                : 'Local model ready',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          Spacer(),
          Text(
            'OFFLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFF9C6BFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.25),
                    blurRadius: 35,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 42,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Your Private AI Assistant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Run AI locally on your device.\n'
              'No cloud. No internet. Your data stays private.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _suggestion(
              Icons.code,
              'Write a Flutter program',
            ),
            _suggestion(
              Icons.school_outlined,
              'Explain machine learning',
            ),
            _suggestion(
              Icons.bug_report_outlined,
              'Help me fix my code',
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestion(IconData icon, String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF121821),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: Colors.white60,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: Colors.white30,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelPicker extends StatefulWidget {
  final ModelManager manager;
  final LocalModel? activeModel;

  const _ModelPicker({required this.manager, required this.activeModel});

  @override
  State<_ModelPicker> createState() => _ModelPickerState();
}

class _ModelPickerState extends State<_ModelPicker> {
  final _searchController = TextEditingController();
  List<LocalModel> _localModels = const [];
  List<HuggingFaceModel> _results = const [];
  bool _searching = false;
  String? _error;
  double? _progress;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLocalModels();
  }

  Future<void> _loadLocalModels() async {
    final models = await widget.manager.localModels();
    if (mounted) setState(() => _localModels = models);
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await widget.manager.search(_searchController.text);
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _download(HuggingFaceModel model) async {
    try {
      final files = await widget.manager.filesFor(model.id);
      if (!mounted || files.isEmpty) return;
      final file = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF1A222D),
        builder: (context) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Choose a GGUF file',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...files.map((name) => ListTile(
                  title: Text(name),
                  onTap: () => Navigator.pop(context, name),
                )),
          ],
        ),
      );
      if (file == null) return;
      setState(() => _progress = 0);
      final local = await widget.manager.download(model.id, file, (value) {
        if (mounted) setState(() => _progress = value);
      });
      if (mounted) Navigator.pop(context, local);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Models',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search Hugging Face GGUF models',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward_rounded)),
                filled: true,
                fillColor: const Color(0xFF1A222D),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            if (_progress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text('Downloading ${(_progress! * 100).round()}%',
                  textAlign: TextAlign.center),
            ],
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent))),
            const SizedBox(height: 12),
            if (_localModels.isNotEmpty) ...[
              const Text('On this device',
                  style: TextStyle(color: Colors.white54)),
              ..._localModels.map((model) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.sd_storage_outlined,
                        color: Colors.greenAccent),
                    title: Text(model.name),
                    trailing: model.path == widget.activeModel?.path
                        ? const Icon(Icons.check, color: Colors.greenAccent)
                        : null,
                    onTap: () => Navigator.pop(context, model),
                  )),
            ],
            if (_searching)
              const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator())),
            ..._results.map((model) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: Text(model.displayName),
                  subtitle: Text('${model.downloads} downloads'),
                  onTap: _progress == null ? () => _download(model) : null,
                )),
          ],
        ),
      ),
    );
  }
}
