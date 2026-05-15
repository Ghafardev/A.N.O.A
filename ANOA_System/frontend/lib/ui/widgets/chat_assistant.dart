import 'package:flutter/material.dart';
import '../../services/api_service.dart';

const _kBg      = Color(0xFF0A0E1A);
const _kSurface = Color(0xFF101626);
const _kCard    = Color(0xFF1A2035);
const _kBorder  = Color(0xFF283050);
const _kPrimary = Color(0xFF6C63FF);
const _kCyan    = Color(0xFF00E5FF);
const _kText2   = Color(0xFF8892B0);

// ─── Model Pesan Chat ─────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, required this.isUser})
      : time = DateTime.now();
}

// ─── Widget Chat Assistant (Reusable) ────────────────────────────────────────
class ChatAssistant extends StatefulWidget {
  final VoidCallback? onClose;
  const ChatAssistant({super.key, this.onClose});

  @override
  State<ChatAssistant> createState() => _ChatAssistantState();
}

class _ChatAssistantState extends State<ChatAssistant> {
  final _controller    = TextEditingController();
  final _scrollCtrl    = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: '👋 Halo! Saya **ANOA AI Assistant** – Purple Team Security.\n\n'
            'Anda bisa bertanya tentang:\n'
            '• Analisis kerentanan kode\n'
            '• Deteksi pola phishing\n'
            '• Audit log keamanan\n'
            '• Strategi mitigasi ancaman\n\n'
            'Pilih mode di bawah, lalu ketik pesan Anda.',
      isUser: false,
    ),
  ];
  bool _isLoading = false;
  String _mode = 'blue_team';

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    final reply = await ApiService.analyze(data: text, mode: _mode);

    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(left: BorderSide(color: _kBorder)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildModeSelector(),
          Expanded(child: _buildMessageList()),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimary, _kCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ANOA AI',
                  style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Purple Team Assistant',
                  style: TextStyle(color: _kText2, fontSize: 11)),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: _kText2, size: 20),
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // ── Mode Selector ────────────────────────────────────────────────────────────
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          _buildModeBtn('red_team',  '🔴 Red Team',  const Color(0xFFF87171)),
          const SizedBox(width: 6),
          _buildModeBtn('blue_team', '🔵 Blue Team', _kCyan),
        ],
      ),
    );
  }

  Widget _buildModeBtn(String mode, String label, Color color) {
    final isSelected = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.5) : _kBorder),
          ),
          child: Center(
            child: Text(label,
              style: TextStyle(
                color: isSelected ? color : _kText2,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              )),
          ),
        ),
      ),
    );
  }

  // ── Daftar Pesan ─────────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: msg.isUser ? _kPrimary : _kCard,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: msg.isUser
              ? null
              : Border.all(color: _kBorder, width: 0.5),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.white.withOpacity(0.9),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
          ),
          const SizedBox(width: 10),
          const Text('ANOA AI sedang menganalisis...',
            style: TextStyle(color: _kText2, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Input Bar ─────────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(
                hintText: 'Masukkan query keamanan...',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isLoading ? null : _sendMessage,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
