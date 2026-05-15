import 'package:flutter/material.dart';
import '../../services/api_service.dart';

const _kCard = Color(0xFF1A2035);
const _kBorder = Color(0xFF283050);
const _kPrimary = Color(0xFF6C63FF);
const _kCyan = Color(0xFF00E5FF);
const _kDanger = Color(0xFFF87171);
const _kText2 = Color(0xFF8892B0);
const _kSuccess = Color(0xFF34D399);
const _kWarning = Color(0xFFFBBF24);

// ─── Mode Configuration ───────────────────────────────────────────────────────
class _ModeConfig {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  final String hint;
  const _ModeConfig(this.id, this.label, this.emoji, this.color, this.hint);
}

const _modes = [
  _ModeConfig(
    'blue_team',
    'Blue Team',
    '🔵',
    _kCyan,
    'Deteksi ancaman & rekomendasi pertahanan...',
  ),
  _ModeConfig(
    'red_team',
    'Red Team',
    '🔴',
    _kDanger,
    'Analisis kerentanan & vektor serangan...',
  ),
  _ModeConfig(
    'phishing',
    'Phishing',
    '🎣',
    _kWarning,
    'Tempel teks email/URL yang dicurigai phishing...',
  ),
  _ModeConfig(
    'log_audit',
    'Log Audit',
    '📋',
    _kPrimary,
    'Tempel log server/aplikasi/SIEM untuk diaudit...',
  ),
  _ModeConfig(
    'credential_detector',
    'Cred. Detect',
    '🔐',
    _kSuccess,
    'Tempel kode atau teks yang ingin dicek credential-nya...',
  ),
];

// ─── Model Pesan Chat ─────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, required this.isUser})
    : time = DateTime.now();
}

// ─── Widget Chat Assistant ────────────────────────────────────────────────────
class ChatAssistant extends StatefulWidget {
  final VoidCallback? onClose;
  const ChatAssistant({super.key, this.onClose});

  @override
  State<ChatAssistant> createState() => _ChatAssistantState();
}

class _ChatAssistantState extends State<ChatAssistant> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isLoading = false;
  String _modeId = 'blue_team';

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          '👋 Halo! Saya **ANOA AI** – Purple Team Security Assistant.\n\n'
          'Pilih mode analisis di bawah, lalu kirim teks, kode, log, atau URL '
          'yang ingin Anda analisis. Saya akan memprosesnya menggunakan Gemini AI.\n\n'
          '🔵 **Blue Team** – Pertahanan & mitigasi\n'
          '🔴 **Red Team** – Analisis kerentanan\n'
          '🎣 **Phishing** – Deteksi social engineering\n'
          '📋 **Log Audit** – Analisis log & SOC\n'
          '🔐 **Cred. Detect** – Deteksi credential bocor',
      isUser: false,
    ),
  ];

  _ModeConfig get _currentMode =>
      _modes.firstWhere((m) => m.id == _modeId, orElse: () => _modes.first);

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    final reply = await ApiService.analyze(data: text, mode: _modeId);

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
        color: Color(0xFF101626),
        border: Border(left: BorderSide(color: _kBorder)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildModeSelector(),
          Expanded(child: _buildMessages()),
          if (_isLoading) _buildTyping(),
          _buildInput(),
        ],
      ),
    );
  }

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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimary, _kCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ANOA AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Mode: ${_currentMode.emoji} ${_currentMode.label}',
                  style: TextStyle(
                    color: _currentMode.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _modes.map((m) {
            final selected = _modeId == m.id;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => setState(() => _modeId = m.id),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? m.color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? m.color.withValues(alpha: 0.5)
                          : _kBorder,
                    ),
                  ),
                  child: Text(
                    '${m.emoji} ${m.label}',
                    style: TextStyle(
                      color: selected ? m.color : _kText2,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessages() {
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
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: msg.isUser ? null : Border.all(color: _kBorder, width: 0.5),
        ),
        child: SelectableText(
          msg.text,
          style: TextStyle(
            color: msg.isUser
                ? Colors.white
                : Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _currentMode.color,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_currentMode.emoji} Gemini sedang menganalisis...',
            style: const TextStyle(color: _kText2, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
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
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: _currentMode.hint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isLoading ? null : _send,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [
                          _kPrimary.withValues(alpha: 0.4),
                          _kCyan.withValues(alpha: 0.4),
                        ]
                      : [_kPrimary, _kCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
