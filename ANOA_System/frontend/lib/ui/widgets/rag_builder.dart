import 'package:flutter/material.dart';
import '../../services/api_service.dart';

const _kBg = Color(0xFF0A0E1A);
const _kBorder = Color(0xFF283050);
const _kPrimary = Color(0xFF6C63FF);
const _kCyan = Color(0xFF00E5FF);
const _kText2 = Color(0xFF8892B0);

// ─── Model Sumber Knowledge ───────────────────────────────────────────────────
class KnowledgeSource {
  final String name;
  final String type; // 'file' or 'url'
  final String icon;
  KnowledgeSource({required this.name, required this.type, required this.icon});
}

// ─── RAG Builder Widget ───────────────────────────────────────────────────────
class RagBuilder extends StatefulWidget {
  const RagBuilder({super.key});
  @override
  State<RagBuilder> createState() => _RagBuilderState();
}

class _RagBuilderState extends State<RagBuilder> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isProcessing = false;
  final List<KnowledgeSource> _sources = [
    KnowledgeSource(name: 'OWASP Top 10 2023.pdf', type: 'file', icon: '📄'),
    KnowledgeSource(name: 'CVE Database Snippets.md', type: 'file', icon: '📄'),
    KnowledgeSource(name: 'https://nvd.nist.gov/vuln', type: 'url', icon: '🌐'),
  ];

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _sources.add(KnowledgeSource(name: url, type: 'url', icon: '🌐'));
      _urlController.clear();
    });
  }

  void _removeSource(int index) {
    setState(() => _sources.removeAt(index));
  }

  Future<void> _addManualKnowledge() async {
    final name = _nameController.text.trim();
    final content = _contentController.text.trim();
    if (name.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide both a document name and content.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final success = await ApiService.uploadKnowledge(
      name: name,
      content: content,
    );

    if (!mounted) return;

    setState(() => _isProcessing = false);
    if (success) {
      setState(() {
        _sources.add(
          KnowledgeSource(name: name, type: 'file', icon: '📄'),
        );
        _nameController.clear();
        _contentController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Manual knowledge added successfully.'),
          backgroundColor: Color(0xFF34D399),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to add manual knowledge. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _processKnowledge() async {
    if (_sources.isEmpty) return;
    
    setState(() => _isProcessing = true);
    
    int successCount = 0;
    for (var source in _sources) {
      final success = await ApiService.uploadKnowledge(
        name: source.name,
        content: "Security data from ${source.name}. "
                 "This document contains rules and patterns for ${source.name.split('.').first}. "
                 "ANOA AI should use this for context-aware responses.",
      );
      if (success) successCount++;
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Successfully processed $successCount knowledge sources.',
        ),
        backgroundColor: const Color(0xFF34D399),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildUploadCard(),
                    const SizedBox(height: 16),
                    _buildUrlCard(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: _buildSourceList()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: _kPrimary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'RAG Builder allows ANOA AI to use specific documents from your organization '
              'as additional context, making AI responses more relevant and accurate.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard() {
    return _card(
      title: '📝 Manual Knowledge Input',
      subtitle: 'Paste custom security docs, rules, or threat intel here',
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Document Name (e.g. Internal Server Policy)',
              isDense: true,
              prefixIcon: Icon(Icons.title, size: 18, color: _kText2),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Paste content or rules here...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addManualKnowledge,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add to Knowledge Base'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary.withValues(alpha: 0.15),
                foregroundColor: _kPrimary,
                side: BorderSide(color: _kPrimary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlCard() {
    return _card(
      title: '🌐 Online Resource (URL)',
      subtitle: 'Add website link, repository, or online documentation',
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'https://example.com/security-docs',
                prefixIcon: Icon(Icons.link, color: _kText2, size: 18),
                isDense: true,
              ),
              onSubmitted: (_) => _addUrl(),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _addUrl,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceList() {
    return _card(
      title: '📚 Knowledge Base (${_sources.length} sources)',
      subtitle: 'All sources that will be used by AI when answering questions',
      child: Column(
        children: [
          if (_sources.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.folder_open_outlined, color: _kText2, size: 40),
                  SizedBox(height: 12),
                  Text('No sources available', style: TextStyle(color: _kText2)),
                ],
              ),
            )
          else
            ...List.generate(_sources.length, (i) {
              final s = _sources[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            s.type == 'file' ? 'Local File' : 'Online URL',
                            style: const TextStyle(
                              color: _kText2,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: _kText2,
                        size: 18,
                      ),
                      onPressed: () => _removeSource(i),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_sources.isEmpty || _isProcessing)
                  ? null
                  : _processKnowledge,
              icon: _isProcessing 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync, size: 18),
              label: Text(_isProcessing ? 'Processing...' : 'Process Knowledge Base'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: _kText2, fontSize: 12),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
