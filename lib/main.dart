import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const OrbitalApp());
}

class OrbitalApp extends StatelessWidget {
  const OrbitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbital 3 Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F18), // Deep Dark Background
        primaryColor: const Color(0xFF00F0FF), // Neon Teal
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131C2A),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF00F0FF)),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF00F0FF),
          selectionColor: Color(0x5500F0FF),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  
  // Advanced History State
  final List<Map<String, dynamic>> _historySessions = [
    {"title": "Hardware Setup (LM317)", "pinned": true},
    {"title": "Math & Logic Gates", "pinned": false},
    {"title": "GGUF Engine Config", "pinned": false},
  ];

  bool _isLoading = false;
  bool _isThinkingMode = false;
  double _selectedTemperature = 0.9;

  void _sendMessage({String? overrideText}) {
    final textToSend = overrideText ?? _controller.text.trim();
    if (textToSend.isEmpty) return;
    
    setState(() {
      _messages.add({"sender": "user", "text": textToSend});
      _isLoading = true;
    });
    _controller.clear();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        String responseText = _isThinkingMode 
            ? "[Thinking Process]\n- Analyzing variables\n- Executing precise reasoning\n\n[Output]\nTask executed with Neon-Teal parameters."
            : "Orbital 3 Pro active. How can I assist you further?";
            
        _messages.add({"sender": "orbital", "text": responseText});
        _isLoading = false;
      });
    });
  }

  void _editUserMessage(String text) {
    _controller.text = text;
    // In a real app, you might truncate messages below this point here.
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response copied to clipboard', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xFF00F0FF),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareMessage(String text) {
    // Note: True native sharing requires the 'share_plus' plugin.
    // This is the UI binding for it.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share triggered (Requires share_plus plugin)'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _togglePin(int index) {
    setState(() {
      _historySessions[index]["pinned"] = !_historySessions[index]["pinned"];
      // Re-sort: Pinned items at the top
      _historySessions.sort((a, b) {
        if (a["pinned"] == b["pinned"]) return 0;
        return a["pinned"] ? -1 : 1;
      });
    });
    Navigator.pop(context); // Close drawer
  }

  void _deleteSession(int index) {
    setState(() {
      _historySessions.removeAt(index);
    });
    Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    const neonTeal = Color(0xFF00F0FF);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orbital 3 Pro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(
              'Offline Engine (1.5B) • Temp: $_selectedTemperature', 
              style: TextStyle(fontSize: 12, color: _isThinkingMode ? Colors.amberAccent : neonTeal),
            ),
          ],
        ),
        actions: [
          DropdownButton<double>(
            value: _selectedTemperature,
            dropdownColor: const Color(0xFF131C2A),
            underline: const SizedBox(),
            icon: const Icon(Icons.tune, color: neonTeal, size: 20),
            items: const [
              DropdownMenuItem(value: 0.1, child: Text('0.1 (Max Effort)', style: TextStyle(color: Colors.white, fontSize: 13))),
              DropdownMenuItem(value: 0.5, child: Text('0.5 (High Effort)', style: TextStyle(color: Colors.white, fontSize: 13))),
              DropdownMenuItem(value: 0.9, child: Text('0.9 (Default)', style: TextStyle(color: Colors.white, fontSize: 13))),
            ],
            onChanged: (val) { if (val != null) setState(() => _selectedTemperature = val); },
          ),
          const SizedBox(width: 4),
          Switch(
            value: _isThinkingMode,
            activeColor: Colors.amberAccent,
            inactiveThumbColor: neonTeal.withOpacity(0.5),
            inactiveTrackColor: Colors.black26,
            onChanged: (val) => setState(() => _isThinkingMode = val),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF131C2A),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16),
              color: const Color(0xFF0A0F18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orbital 3 Pro', style: TextStyle(color: neonTeal, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Local History', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: neonTeal),
              title: const Text('New Chat', style: TextStyle(color: neonTeal, fontWeight: FontWeight.bold)),
              onTap: () {
                setState(() => _messages.clear());
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _historySessions.length,
                itemBuilder: (context, index) {
                  final session = _historySessions[index];
                  return ListTile(
                    leading: Icon(
                      session["pinned"] ? Icons.push_pin : Icons.chat_bubble_outline,
                      color: session["pinned"] ? neonTeal : Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      session["title"],
                      style: TextStyle(color: session["pinned"] ? Colors.white : Colors.white70, fontSize: 14),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                      color: const Color(0xFF1A2639),
                      onSelected: (value) {
                        if (value == 'pin') _togglePin(index);
                        if (value == 'delete') _deleteSession(index);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Text(session["pinned"] ? 'Unpin' : 'Pin', style: const TextStyle(color: Colors.white)),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                
                return Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF131C2A) : Colors.transparent,
                        border: isUser ? Border.all(color: neonTeal.withOpacity(0.3)) : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        msg["text"] ?? "",
                        style: TextStyle(color: isUser ? neonTeal : Colors.white, fontSize: 15, height: 1.4),
                      ),
                    ),
                    // Action Buttons Row
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: isUser
                            ? [ // User Actions
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                                  onPressed: () => _editUserMessage(msg["text"]!),
                                  tooltip: "Edit Prompt",
                                ),
                              ]
                            : [ // Orbital Actions
                                IconButton(
                                  icon: const Icon(Icons.content_copy, size: 16, color: Colors.grey),
                                  onPressed: () => _copyToClipboard(msg["text"]!),
                                  tooltip: "Copy",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, size: 16, color: Colors.grey),
                                  onPressed: () => _shareMessage(msg["text"]!),
                                  tooltip: "Share",
                                ),
                              ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                backgroundColor: const Color(0xFF131C2A),
                color: _isThinkingMode ? Colors.amberAccent : neonTeal,
              ),
            ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF131C2A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: neonTeal.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask Orbital 3 Pro...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: neonTeal,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
