import 'package:flutter/material.dart';

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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
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
  final List<String> _historySessions = ["Session 1 - Hardware Setup", "Session 2 - Math & Logic"];
  bool _isLoading = false;
  bool _isThinkingMode = false; // Toggle state for reasoning/thinking mode

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    final userText = _controller.text.trim();
    setState(() {
      _messages.add({"sender": "user", "text": userText});
      _isLoading = true;
    });
    _controller.clear();

    // Simulated response handling considering Thinking Mode state
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        String responseText = _isThinkingMode 
            ? "[Thinking Process]\n- Analyzing query structure\n- Applying step-by-step reasoning logic\n\n[Orbital 3 Pro Output]\nResponse generated with deep reasoning active."
            : "Orbital 3 Pro active. Ready to assist.";
            
        _messages.add({"sender": "orbital", "text": responseText});
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orbital 3 Pro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              _isThinkingMode ? 'Thinking Mode Active (1.5B)' : 'Standard Mode (1.5B)', 
              style: TextStyle(fontSize: 12, color: _isThinkingMode ? Colors.amberAccent : Colors.cyanAccent),
            ),
          ],
        ),
        actions: [
          // Toggle switch for Thinking Mode
          Row(
            children: [
              const Icon(Icons.psychology, size: 20),
              Switch(
                value: _isThinkingMode,
                activeColor: Colors.amberAccent,
                onChanged: (val) {
                  setState(() {
                    _isThinkingMode = val;
                  });
                },
              ),
            ],
          )
        ],
      ),
      // History Drawer Tab
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E293B),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0F172A)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Orbital 3 Pro', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Chat History & Logs', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.cyanAccent),
              title: const Text('New Chat', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _messages.clear();
                });
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white24),
            ..._historySessions.map((session) => ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
              title: Text(session, style: const TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
              },
            )),
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
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(color: _isThinkingMode ? Colors.amberAccent : Colors.cyanAccent),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Message Orbital 3 Pro...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: _isThinkingMode ? Colors.amberAccent : Colors.cyanAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
