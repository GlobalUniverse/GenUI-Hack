import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../services/chat_provider.dart';
import '../widgets/dynamic/widget_renderer.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = [
    'Can I afford a \$120 dinner tonight?',
    'Where did I overspend this month?',
    'How do I save \$1,000 in 60 days?',
    'What should I do before rent hits tomorrow?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    context.read<ChatProvider>().sendMessage(text.trim());
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FinPilot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('AI Financial Advisor', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        actions: [
          if (provider.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white38),
              onPressed: () => context.read<ChatProvider>().clearChat(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.messages.isEmpty
                ? _emptyState(provider.isLoading)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == provider.messages.length) return _typingIndicator();
                      return _buildMessage(provider.messages[i], provider.snapshot);
                    },
                  ),
          ),
          _inputBar(provider.isLoading),
        ],
      ),
    );
  }

  Widget _emptyState(bool loading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF00BFA5)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('Ask me anything about your money', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('I have access to your spending, savings, and upcoming bills.', style: TextStyle(color: Colors.white38, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ..._suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: loading ? null : () => _send(s),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg, snapshot) {
    final isUser = msg.role == MessageRole.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(bottom: 4, left: 4),
              child: Text('FinPilot', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF4FC3F7) : const Color(0xFF1E2A3A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: isUser
                ? Text(msg.text, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4))
                : MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      em: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 14),
                      code: const TextStyle(color: Color(0xFF4FC3F7), fontFamily: 'monospace', fontSize: 13),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      listBullet: const TextStyle(color: Colors.white70, fontSize: 14),
                      h1: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      h3: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 14, fontWeight: FontWeight.w600),
                      blockquoteDecoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Color(0xFF4FC3F7), width: 3)),
                        color: Colors.black12,
                      ),
                      blockquote: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
          ),
          if (!isUser && msg.widgets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: DynamicWidgetRenderer(specs: msg.widgets, snapshot: snapshot),
            ),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF1E2A3A), borderRadius: BorderRadius.circular(16)),
          child: const Row(children: [
            _Dot(delay: 0),
            SizedBox(width: 4),
            _Dot(delay: 150),
            SizedBox(width: 4),
            _Dot(delay: 300),
          ]),
        ),
      ]),
    );
  }

  Widget _inputBar(bool loading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1923),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ask about your finances...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1E2A3A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
            onSubmitted: loading ? null : _send,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: loading ? null : () => _send(_controller.text),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: loading
                  ? null
                  : const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF00BFA5)]),
              color: loading ? Colors.white12 : null,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(loading ? Icons.hourglass_empty : Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle)),
  );
}
