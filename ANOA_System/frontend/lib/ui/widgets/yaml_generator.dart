import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

const _kBg = Color(0xFF0A0E1A);
const _kBorder = Color(0xFF283050);
const _kPrimary = Color(0xFF6C63FF);
const _kCyan = Color(0xFF00E5FF);
const _kText2 = Color(0xFF8892B0);
const _kSuccess = Color(0xFF34D399);

class YamlGenerator extends StatefulWidget {
  const YamlGenerator({super.key});
  @override
  State<YamlGenerator> createState() => _YamlGeneratorState();
}

class _YamlGeneratorState extends State<YamlGenerator> {
  final _promptController = TextEditingController();
  String _generatedYaml = '';
  bool _isGenerating = false;

  final _quickPrompts = [
    '🚫 Blokir semua prompt injection attempt',
    '🔐 Deteksi kebocoran API Key dan credential',
    '🎣 Cegah pola phishing dalam output AI',
    '🛡️ Batasi output data PII (nama, email, NIK)',
    '⚠️ Tandai respons yang mengandung exploit code',
    '🤖 Blokir jailbreak dan model manipulation',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generatedYaml = '';
    });

    final result = await ApiService.generateYaml(prompt: prompt);

    if (!mounted) return;

    setState(() {
      _isGenerating = false;
      if (result != null) {
        _generatedYaml = result;
      } else {
        _generatedYaml = '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal membuat YAML. Periksa koneksi backend.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedYaml));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ YAML disalin ke clipboard!'),
        backgroundColor: _kSuccess,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCyan.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kCyan.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_fix_high, color: _kCyan, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tuliskan kebijakan keamanan dalam bahasa natural. '
                    'Gemini AI akan men-generate YAML rules siap pakai untuk Veea Lobster Trap.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick prompts
          const Text(
            'Quick Templates:',
            style: TextStyle(
              color: _kText2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _quickPrompts
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _promptController.text = p),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _kBorder.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Text(
                            p,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Split view
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInputPanel()),
                const SizedBox(width: 16),
                Expanded(child: _buildOutputPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: _kPrimary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Describe Security Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Jelaskan aturan keamanan yang Anda inginkan (Bahasa Indonesia/Inggris)',
              style: TextStyle(color: _kText2, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _promptController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText:
                      'Contoh: "Blokir semua permintaan yang mengandung pola '
                      'prompt injection, terutama yang mencoba '
                      'melewati filter dengan kata ignore previous instructions..."',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  _isGenerating
                      ? 'Gemini sedang generate...'
                      : '✨ Generate YAML Rule',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.code_rounded, color: _kCyan, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Generated YAML Rule',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_generatedYaml.isNotEmpty)
                  InkWell(
                    onTap: _copyToClipboard,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _kSuccess.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _kSuccess.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.copy, color: _kSuccess, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Copy',
                            style: TextStyle(color: _kSuccess, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Output Gemini AI – siap pakai untuk Veea Lobster Trap',
              style: TextStyle(color: _kText2, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _generatedYaml.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.code_off_rounded,
                            color: _kText2.withValues(alpha: 0.3),
                            size: 52,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Output YAML akan muncul di sini',
                            style: TextStyle(color: _kText2),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'setelah Anda klik "Generate"',
                            style: TextStyle(color: _kText2, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _generatedYaml,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
