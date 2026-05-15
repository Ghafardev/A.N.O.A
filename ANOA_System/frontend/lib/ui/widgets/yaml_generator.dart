import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _kBg      = Color(0xFF0A0E1A);
const _kSurface = Color(0xFF101626);
const _kCard    = Color(0xFF1A2035);
const _kBorder  = Color(0xFF283050);
const _kPrimary = Color(0xFF6C63FF);
const _kCyan    = Color(0xFF00E5FF);
const _kText2   = Color(0xFF8892B0);
const _kSuccess = Color(0xFF34D399);

// ─── YAML Generator Widget ────────────────────────────────────────────────────
class YamlGenerator extends StatefulWidget {
  const YamlGenerator({super.key});
  @override
  State<YamlGenerator> createState() => _YamlGeneratorState();
}

class _YamlGeneratorState extends State<YamlGenerator> {
  final _promptController = TextEditingController();
  String _generatedYaml = '';
  bool _isGenerating = false;

  // Template rules cepat
  final _quickPrompts = [
    '🚫 Blokir semua prompt injection attempt',
    '🔐 Deteksi kebocoran API Key dan credential',
    '🎣 Cegah pola phishing dalam respons AI',
    '🛡️ Batasi output data PII (nama, email, NIK)',
    '⚠️ Tandai respons yang mengandung exploit code',
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

    // Simulasi generate YAML (di Tahap 4 akan dihubungkan ke Gemini)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isGenerating = false;
      _generatedYaml = _buildSampleYaml(prompt);
    });
  }

  /// Menghasilkan contoh YAML berdasarkan prompt (placeholder untuk Tahap 4)
  String _buildSampleYaml(String prompt) {
    final ts = DateTime.now().toIso8601String().substring(0, 10);
    return '''# ANOA System – Custom Security Rule
# Generated: $ts
# Prompt: "$prompt"
# Note: Rule ini akan di-generate oleh Gemini AI di Tahap 4

rules:
  - name: anoa_custom_rule_001
    description: >
      ${prompt.length > 60 ? prompt.substring(0, 60) + '...' : prompt}
    severity: HIGH
    action: BLOCK
    
    conditions:
      - type: content_pattern
        match_mode: regex
        patterns:
          - "(?i)(ignore|forget|disregard).*(previous|above|system).*(prompt|instruction)"
          - "(?i)(jailbreak|bypass|override).*(safety|filter|policy)"
          - "(?i)(reveal|expose|show).*(api.?key|secret|password|token)"
          - "(?i)(act as|pretend|roleplay).*(hacker|attacker|malicious)"
        
      - type: response_filter
        check: outbound
        block_patterns:
          - "(?:sk-|AIza|ghp_)[A-Za-z0-9]{20,}"  # API keys
          - "\\b[0-9]{16}\\b"                      # Card numbers
          
    response:
      status_code: 403
      message: "Request blocked by ANOA Security Policy"
      log: true
      alert_level: HIGH
      
    metadata:
      created_by: ANOA_AI
      version: "1.0"
      tags:
        - purple-team
        - auto-generated
''';
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
              color: _kCyan.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kCyan.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_fix_high, color: _kCyan, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tuliskan kebijakan keamanan dalam bahasa natural, dan AI akan men-generate '
                    'YAML rules siap pakai untuk Veea Lobster Trap.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick prompts
          const Text('Quick Templates:',
            style: TextStyle(color: _kText2, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _quickPrompts.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _promptController.text = p),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Text(p,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Split view
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kiri: Input prompt
                Expanded(child: _buildInputPanel()),
                const SizedBox(width: 16),
                // Kanan: Output YAML
                Expanded(child: _buildOutputPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Panel ───────────────────────────────────────────────────────────────
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
                Text('Describe Security Policy',
                  style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Jelaskan aturan keamanan yang Anda inginkan dalam bahasa natural',
              style: TextStyle(color: _kText2, fontSize: 12)),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _promptController,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Contoh: "Blokir semua request yang mengandung pola prompt injection, '
                      'khususnya yang mencoba melewati sistem keamanan dengan kata-kata seperti '
                      'ignore previous instructions atau act as..."',
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
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_isGenerating ? 'Generating...' : '✨ Generate YAML Rule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Output Panel ──────────────────────────────────────────────────────────────
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
                const Text('Generated YAML Rule',
                  style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                if (_generatedYaml.isNotEmpty)
                  InkWell(
                    onTap: _copyToClipboard,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kSuccess.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kSuccess.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.copy, color: _kSuccess, size: 14),
                          SizedBox(width: 6),
                          Text('Copy', style: TextStyle(color: _kSuccess, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Format YAML siap pakai untuk Veea Lobster Trap',
              style: TextStyle(color: _kText2, fontSize: 12)),
            const SizedBox(height: 16),
            Expanded(
              child: _generatedYaml.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.code_off_rounded,
                            color: _kText2.withOpacity(0.4), size: 48),
                          const SizedBox(height: 16),
                          const Text('YAML akan muncul di sini',
                            style: TextStyle(color: _kText2)),
                          const SizedBox(height: 4),
                          const Text('setelah Anda klik "Generate"',
                            style: TextStyle(color: _kText2, fontSize: 12)),
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
                        child: Text(
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
