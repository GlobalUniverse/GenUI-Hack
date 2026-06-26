import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../main.dart';
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
      backgroundColor: AppColors.card,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('FinPilot', style: TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w700)),
                  const Text('AI Financial Advisor', style: TextStyle(color: AppColors.inkLight, fontSize: 11)),
                ]),
                if (provider.messages.isNotEmpty)
                  GestureDetector(
                    onTap: () => context.read<ChatProvider>().clearChat(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Clear', style: TextStyle(color: AppColors.inkMid, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.messages.isEmpty
                ? _emptyState(provider.isLoading)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          const SizedBox(height: 48),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 20),
          const Text('Ask me anything\nabout your money', style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.3), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('I have access to your spending,\nsavings, and upcoming bills.', style: TextStyle(color: AppColors.inkMid, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ..._suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: loading ? null : () => _send(s),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Expanded(child: Text(s, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w400))),
                  const Icon(Icons.arrow_forward, color: AppColors.inkLight, size: 15),
                ]),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(bottom: 4, left: 2),
              child: Text('FinPilot', style: TextStyle(color: AppColors.inkLight, fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.ink : AppColors.divider,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: isUser
                ? Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4))
                : MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.45),
                      strong: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 14),
                      em: const TextStyle(color: AppColors.inkMid, fontStyle: FontStyle.italic, fontSize: 14),
                      code: const TextStyle(color: AppColors.ink, fontFamily: 'monospace', fontSize: 13),
                      codeblockDecoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      listBullet: const TextStyle(color: AppColors.inkMid, fontSize: 14),
                      h1: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold),
                      h2: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold),
                      h3: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
                      blockquoteDecoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: AppColors.inkMid, width: 3)),
                        color: AppColors.bg,
                      ),
                      blockquote: const TextStyle(color: AppColors.inkMid, fontSize: 14),
                    ),
                  ),
          ),
          if (!isUser && msg.widgets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: DynamicWidgetRenderer(specs: msg.widgets, snapshot: snapshot),
            ),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(16)),
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
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: AppColors.ink, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ask about your finances...',
              hintStyle: const TextStyle(color: AppColors.inkLight, fontSize: 14),
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.inkMid)),
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
              color: loading ? AppColors.border : AppColors.ink,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(loading ? Icons.hourglass_empty : Icons.arrow_upward_rounded, color: Colors.white, size: 20),
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
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.inkMid, shape: BoxShape.circle)),
  );
}
