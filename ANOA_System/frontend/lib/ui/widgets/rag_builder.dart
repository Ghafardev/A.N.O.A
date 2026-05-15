import 'package:flutter/material.dart';

const _kBg      = Color(0xFF0A0E1A);
const _kSurface = Color(0xFF101626);
const _kCard    = Color(0xFF1A2035);
const _kBorder  = Color(0xFF283050);
const _kPrimary = Color(0xFF6C63FF);
const _kCyan    = Color(0xFF00E5FF);
const _kText2   = Color(0xFF8892B0);

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
  final List<KnowledgeSource> _sources = [
    KnowledgeSource(name: 'OWASP Top 10 2023.pdf', type: 'file', icon: '📄'),
    KnowledgeSource(name: 'CVE Database Snippets.md', type: 'file', icon: '📄'),
    KnowledgeSource(name: 'https://nvd.nist.gov/vuln', type: 'url', icon: '🌐'),
  ];

  @override
  void dispose() {
    _urlController.dispose();
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

  void _simulateFilePick() {
    // Placeholder: di Tahap 4 ini akan menggunakan file_picker
    setState(() {
      _sources.add(KnowledgeSource(
        name: 'Security_Report_${DateTime.now().millisecond}.pdf',
        type: 'file',
        icon: '📄',
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File ditambahkan ke knowledge base (integrasi file_picker di Tahap 4)'),
        backgroundColor: _kPrimary,
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
          // Header info
          _buildInfoBanner(),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel kiri: Upload file & URL
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
              // Panel kanan: Daftar sumber
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
        color: _kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _kPrimary, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'RAG Builder memungkinkan ANOA AI menggunakan dokumen spesifik organisasi Anda '
              'sebagai konteks tambahan, sehingga respons AI lebih relevan dan akurat.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard() {
    return _card(
      title: '📁 Upload Dokumen Lokal',
      subtitle: 'Didukung: PDF, TXT, MD, DOCX',
      child: InkWell(
        onTap: _simulateFilePick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(
            border: Border.all(
              color: _kPrimary.withOpacity(0.4),
              style: BorderStyle.solid,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _kPrimary.withOpacity(0.05),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_upload_outlined, color: _kPrimary, size: 40),
              SizedBox(height: 12),
              Text('Klik untuk pilih file',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('atau drag & drop ke sini',
                style: TextStyle(color: _kText2, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlCard() {
    return _card(
      title: '🌐 Online Resource (URL)',
      subtitle: 'Tambahkan link website, repo, atau dokumentasi online',
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
              child: const Text('Add',
                style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceList() {
    return _card(
      title: '📚 Knowledge Base (${_sources.length} sumber)',
      subtitle: 'Semua sumber yang akan digunakan AI saat menjawab',
      child: Column(
        children: [
          if (_sources.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.folder_open_outlined, color: _kText2, size: 40),
                  SizedBox(height: 12),
                  Text('Belum ada sumber',
                    style: TextStyle(color: _kText2)),
                ],
              ),
            )
          else
            ...List.generate(_sources.length, (i) {
              final s = _sources[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          Text(s.name,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                          Text(s.type == 'file' ? 'Local File' : 'Online URL',
                            style: const TextStyle(color: _kText2, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: _kText2, size: 18),
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
              onPressed: _sources.isEmpty
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Knowledge base akan diproses di Tahap 4 (Backend Integration)'),
                        backgroundColor: Color(0xFF34D399),
                      )),
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Proses Knowledge Base'),
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
            Text(title,
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle,
              style: const TextStyle(color: _kText2, fontSize: 12)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
