import 'package:flutter/material.dart';
import 'widgets/chart_widgets.dart';
import 'widgets/chat_assistant.dart';
import 'widgets/rag_builder.dart';
import 'widgets/yaml_generator.dart';

// ─── Konstanta Warna ─────────────────────────────────────────────────────────
const kBg = Color(0xFF0A0E1A);
const kSurface = Color(0xFF101626);
const kCard = Color(0xFF1A2035);
const kBorder = Color(0xFF283050);
const kPrimary = Color(0xFF6C63FF);
const kCyan = Color(0xFF00E5FF);
const kSuccess = Color(0xFF34D399);
const kDanger = Color(0xFFF87171);
const kWarning = Color(0xFFFBBF24);
const kText2 = Color(0xFF8892B0);

// ─── Model Nav Item ───────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ─── Dashboard Screen ─────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNav = 0;
  bool _chatOpen = false;

  final _navItems = const [
    _NavItem(Icons.shield_outlined, 'Overview'),
    _NavItem(Icons.storage_outlined, 'RAG Builder'),
    _NavItem(Icons.code_rounded, 'YAML Generator'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildContent()),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: _chatOpen ? 380 : 0,
                        child: _chatOpen
                            ? ChatAssistant(
                                onClose: () =>
                                    setState(() => _chatOpen = false),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Sidebar ──────────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, kCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ANOA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // Label seksi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'MAIN MENU',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: kText2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Nav items
          ...List.generate(_navItems.length, (i) => _buildNavItem(i)),

          const Spacer(),
          const Divider(color: kBorder, height: 1),

          // Status indikator backend
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: kSuccess,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Backend Active',
                  style: TextStyle(color: kText2, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedNav == index;
    return InkWell(
      onTap: () => setState(() => _selectedNav = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: kPrimary.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(item.icon, color: isSelected ? kPrimary : kText2, size: 20),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? Colors.white : kText2,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final titles = [
      'Security Overview',
      'RAG Knowledge Builder',
      'YAML Rules Generator',
    ];
    final subtitles = [
      'Real-time threat monitoring & analytics',
      'Kelola sumber knowledge base untuk AI',
      'Generate custom firewall rules via AI',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_selectedNav],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitles[_selectedNav],
                  style: const TextStyle(color: kText2, fontSize: 13),
                ),
              ],
            ),
          ),
          // Chat toggle button
          _buildTopBarBtn(
            icon: _chatOpen ? Icons.close : Icons.smart_toy_outlined,
            label: _chatOpen ? 'Tutup Chat' : 'AI Assistant',
            color: kPrimary,
            onTap: () => setState(() => _chatOpen = !_chatOpen),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Konten Utama ──────────────────────────────────────────────────────────────
  Widget _buildContent() {
    switch (_selectedNav) {
      case 0:
        return _buildOverviewPage();
      case 1:
        return const RagBuilder();
      case 2:
        return const YamlGenerator();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Halaman Overview ──────────────────────────────────────────────────────────
  Widget _buildOverviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards
          Row(
            children: [
              _buildStatCard(
                'Threats Detected',
                '1,247',
                Icons.warning_amber_rounded,
                kDanger,
                '+12%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Requests Blocked',
                '389',
                Icons.block_rounded,
                kWarning,
                '+5%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Safe Requests',
                '4,821',
                Icons.check_circle_outline,
                kSuccess,
                '+3%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Active YAML Rules',
                '24',
                Icons.code_rounded,
                kCyan,
                '0%',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line Chart
              Expanded(
                flex: 3,
                child: _buildCard(
                  title: 'DPI Inspection Timeline',
                  subtitle: 'Jumlah inspeksi per jam (24 jam terakhir)',
                  child: const SizedBox(height: 240, child: ThreatLineChart()),
                ),
              ),
              const SizedBox(width: 16),
              // Pie Chart
              Expanded(
                flex: 2,
                child: _buildCard(
                  title: 'Threat Categories',
                  subtitle: 'Distribusi jenis ancaman',
                  child: const SizedBox(height: 240, child: ThreatPieChart()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Threats Table
          _buildCard(
            title: 'Recent Threat Log',
            subtitle: 'Aktivitas ancaman terbaru yang dideteksi Lobster Trap',
            child: _buildThreatTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kSuccess.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      change,
                      style: const TextStyle(
                        color: kSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: kText2, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: kText2, fontSize: 12)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildThreatTable() {
    final threats = [
      ['2m ago', 'Prompt Injection', '192.168.1.45', 'BLOCKED', kDanger],
      ['8m ago', 'Data Leak Attempt', '10.0.0.12', 'BLOCKED', kDanger],
      ['15m ago', 'Phishing Pattern', '203.45.12.8', 'BLOCKED', kWarning],
      ['22m ago', 'Credential Stuffing', '172.16.0.3', 'BLOCKED', kDanger],
      ['31m ago', 'Normal Request', '192.168.1.100', 'ALLOWED', kSuccess],
      ['45m ago', 'Normal Request', '10.0.0.55', 'ALLOWED', kSuccess],
    ];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: kBorder.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Time',
                  style: TextStyle(
                    color: kText2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Type',
                  style: TextStyle(
                    color: kText2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Source',
                  style: TextStyle(
                    color: kText2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Status',
                  style: TextStyle(
                    color: kText2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...threats.map(
          (row) => Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    row[0] as String,
                    style: const TextStyle(color: kText2, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    row[1] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    row[2] as String,
                    style: const TextStyle(color: kText2, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (row[4] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      row[3] as String,
                      style: TextStyle(
                        color: row[4] as Color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Floating Action Button ─────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 480,
              height: 600,
              child: ChatAssistant(onClose: () => Navigator.of(context).pop()),
            ),
          ),
        );
      },
      backgroundColor: kPrimary,
      tooltip: 'Buka AI Assistant (Floating)',
      child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
    );
  }
}
