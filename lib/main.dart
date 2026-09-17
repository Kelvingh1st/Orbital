import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:fllama/fllama.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const OrbitalApp());
}

class MemoryStorage {
  static const String _key = "orbital_memories";

  static Future<void> saveMemory(String fact) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> memories = prefs.getStringList(_key) ?? [];
    memories.add(fact);
    await prefs.setStringList(_key, memories);
  }

  static Future<List<String>> getAllMemories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}

class OrbitalApp extends StatelessWidget {
  const OrbitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F18),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF131C2A)),
      ),
      home: const MainSetupScreen(),
    );
  }
}

class MainSetupScreen extends StatefulWidget {
  const MainSetupScreen({super.key});

  @override
  State<MainSetupScreen> createState() => _MainSetupScreenState();
}

class _MainSetupScreenState extends State<MainSetupScreen> {
  bool _isModelReady = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = "Checking local storage for Orbital...";
  String _modelPath = "";

  final String _modelUrl =
      "https://github.com/Kelvingh1st/Orbital/raw/main/assets/models/qwen2.5-1.5b-instruct-q4_k_m.gguf";

  @override
  void initState() {
    super.initState();
    _checkAndInitModel();
  }

  Future<void> _checkAndInitModel() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/orbital_engine.gguf');
    _modelPath = file.path;

    if (await file.exists()) {
      setState(() {
        _isModelReady = true;
      });
    } else {
      _startDownload(file);
    }
  }

  Future<void> _startDownload(File file) async {
    setState(() {
      _isDownloading = true;
      _statusMessage = "Downloading Orbital Engine (1.12 GB)...";
    });

    try {
      final request = http.Request('GET', Uri.parse(_modelUrl));
      final response = await http.Client().send(request);

      final totalBytes = response.contentLength ?? 1200000000;
      int receivedBytes = 0;

      final sink = file.openWrite();
      await response.stream.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        setState(() {
          _downloadProgress = receivedBytes / totalBytes;
        });
      });

      await sink.close();
      setState(() {
        _isDownloading = false;
        _isModelReady = true;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = "Download failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isModelReady) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF00F0FF)),
                const SizedBox(height: 24),
                Text(_statusMessage, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                if (_isDownloading) ...[
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: const Color(0xFF131C2A),
                    color: const Color(0xFF00F0FF),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(_downloadProgress * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(color: Color(0xFF00F0FF)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return OrbitalMainUi(modelPath: _modelPath);
  }
}

class OrbitalMainUi extends StatefulWidget {
  final String modelPath;
  const OrbitalMainUi({super.key, required this.modelPath});

  @override
  State<OrbitalMainUi> createState() => _OrbitalMainUiState();
}

class _OrbitalMainUiState extends State<OrbitalMainUi> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _thinking = false;
  bool _isGenerating = false;
  String _effortLabel = "Default";
  double _tempValue = 0.9;

  void _setEffort(String label, double temp) {
    setState(() {
      _effortLabel = label;
      _tempValue = temp;
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isGenerating = true;
    });
    _inputController.clear();

    final memories = await MemoryStorage.getAllMemories();
    final memoryBlock = memories.isNotEmpty
        ? "\nLearned User Facts:\n- ${memories.join('\n- ')}"
        : "";

    final baseContext = "You are Orbital, Kelvin's personal offline AI assistant.$memoryBlock";

    final systemPrompt = _thinking
        ? "$baseContext\nAnalyze variables, execute precise reasoning, and think through the problem step-by-step before outputting the result."
        : baseContext;

    final req = OpenAiRequest(
      modelPath: widget.modelPath,
      temperature: _tempValue,
      messages: [
        Message(Role.system, systemPrompt),
        Message(Role.user, text),
      ],
      contextSize: 2048,
    );

    try {
      final response = await fllama(req);
      final reply = response.choices?.first.message.content ?? "No response";

      if (text.toLowerCase().startsWith("remember that") || text.toLowerCase().startsWith("note:")) {
        final factToSave = text.replaceAll(RegExp(r'(?i)remember that|note:'), '').trim();
        if (factToSave.isNotEmpty) {
          await MemoryStorage.saveMemory(factToSave);
        }
      }

      setState(() {
        _messages.add({"role": "assistant", "content": reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "content": "Engine error: $e"});
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _newChat() {
    setState(() {
      _messages.clear();
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final subColor = _thinking ? const Color(0xFFFFD84D) : const Color(0xFF00F0FF);
    final subText =
        "Offline Engine (1.5B) • Effort: $_effortLabel${_thinking ? ' • THINKING' : ''}";

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF131C2A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
              color: const Color(0xFF0A0F18),
              width: double.infinity,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orbital', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Local History & Memory', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Color(0xFF00F0FF)),
              title: const Text('New Chat', style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
              onTap: _newChat,
            ),
            const Divider(color: Colors.white10),
            const ListTile(
              leading: Text('📌', style: TextStyle(fontSize: 16)),
              title: Text('Hardware Setup (LM317)', style: TextStyle(color: Colors.white, fontSize: 14)),
              trailing: Icon(Icons.more_vert, color: Colors.grey),
            ),
            const ListTile(
              leading: Text('◯', style: TextStyle(fontSize: 16, color: Colors.grey)),
              title: Text('Math & Logic Gates', style: TextStyle(color: Colors.white, fontSize: 14)),
              trailing: Icon(Icons.more_vert, color: Colors.grey),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orbital', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(subText, style: TextStyle(fontSize: 11, color: subColor)),
          ],
        ),
        actions: [
          PopupMenuButton<double>(
            icon: const Icon(Icons.settings, color: Color(0xFF00F0FF)),
            color: const Color(0xFF1A2639),
            onSelected: (val) {
              if (val == 0.1) _setEffort("Max Effort", 0.1);
              if (val == 0.5) _setEffort("High Effort", 0.5);
              if (val == 0.9) _setEffort("Default", 0.9);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.1, child: Text('Max Effort (0.1)')),
              const PopupMenuItem(value: 0.5, child: Text('High Effort (0.5)')),
              const PopupMenuItem(value: 0.9, child: Text('Default (0.9)')),
            ],
          ),
          Switch(
            value: _thinking,
            activeColor: const Color(0xFFFFD84D),
            activeTrackColor: const Color(0xFF6E5B14),
            inactiveThumbColor: const Color(0xFF00F0FF),
            inactiveTrackColor: const Color(0xFF252B35),
            onChanged: (v) => setState(() => _thinking = v),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('◎', style: TextStyle(fontSize: 44, color: Color(0xFF00F0FF))),
                        SizedBox(height: 8),
                        Text('Orbital', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Local AI • Memory Active', style: TextStyle(color: Color(0xFF687384))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      final text = msg['content'] ?? '';

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
                          child: Column(
                            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser ? const Color(0xFF131C2A) : Colors.transparent,
                                  border: isUser ? Border.all(color: const Color(0xFF00F0FF).withOpacity(0.33)) : null,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    color: isUser ? const Color(0xFF00F0FF) : Colors.white,
                                    fontSize: 15,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isUser)
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16, color: Color(0xFF707887)),
                                      onPressed: () {
                                        _inputController.text = text;
                                      },
                                    )
                                  else ...[
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 16, color: Color(0xFF707887)),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: text));
                                      },
                                    ),
                                  ]
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isGenerating)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFF131C2A),
              color: Color(0xFF00F0FF),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: const Color(0xFF0A0F18),
            child: Container(
              padding: const EdgeInsets.only(left: 15, right: 6, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF131C2A),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Ask Orbital...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  InkWell(
                    onTap: _sendMessage,
                    child: const CircleAvatar(
                      radius: 21,
                      backgroundColor: Color(0xFF00F0FF),
                      child: Icon(Icons.arrow_upward, color: Colors.black, size: 22),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
