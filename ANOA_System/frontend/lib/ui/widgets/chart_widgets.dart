import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

const kPrimary = Color(0xFF6C63FF);
const kCyan = Color(0xFF00E5FF);
const kDanger = Color(0xFFF87171);
const kWarning = Color(0xFFFBBF24);
const kSuccess = Color(0xFF34D399);
const kBorder = Color(0xFF283050);
const kText2 = Color(0xFF8892B0);

// ─── Line Chart: Inspeksi DPI per Jam ────────────────────────────────────────
class ThreatLineChart extends StatelessWidget {
  final List<dynamic>? data;
  const ThreatLineChart({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data != null
        ? data!.map((d) => FlSpot(d['hour'].toDouble(), d['count'].toDouble())).toList()
        : [
            FlSpot(0, 12), FlSpot(5, 67), FlSpot(10, 62),
            FlSpot(15, 71), FlSpot(20, 38), FlSpot(23, 35),
          ];

    return LineChart(
// ...
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(colors: [kPrimary, kCyan]),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  kPrimary.withValues(alpha: 0.3),
                  kCyan.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: kBorder, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: kText2, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}h',
                style: const TextStyle(color: kText2, fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: 100,
      ),
    );
  }
}

// ─── Pie Chart: Kategori Ancaman ─────────────────────────────────────────────
class ThreatPieChart extends StatefulWidget {
  final List<dynamic>? data;
  const ThreatPieChart({super.key, this.data});
  @override
  State<ThreatPieChart> createState() => _ThreatPieChartState();
}

class _ThreatPieChartState extends State<ThreatPieChart> {
  int _touched = -1;

  List<_PieSection> get _sections {
    if (widget.data == null || widget.data!.isEmpty) {
      return const [
        _PieSection('Prompt Injection', 35, kDanger),
        _PieSection('Phishing', 28, kWarning),
        _PieSection('Data Leak', 20, kPrimary),
        _PieSection('Others', 17, kSuccess),
      ];
    }
    
    final colors = [kDanger, kWarning, kPrimary, kCyan, kSuccess];
    return List.generate(widget.data!.length, (i) {
      final d = widget.data![i];
      return _PieSection(d['label'], d['value'].toDouble(), colors[i % colors.length]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionsData = _sections;
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touched =
                        (event.isInterestedForInteractions &&
                            response?.touchedSection != null)
                        ? response!.touchedSection!.touchedSectionIndex
                        : -1;
                  });
                },
              ),
              sections: List.generate(sectionsData.length, (i) {
                final s = sectionsData[i];
                final isT = i == _touched;
                return PieChartSectionData(
                  value: s.value,
                  color: s.color,
                  radius: isT ? 85 : 72,
                  title: '${s.value.toInt()}',
                  titleStyle: TextStyle(
                    fontSize: isT ? 14 : 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }),
              centerSpaceRadius: 36,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sectionsData
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.label,
                        style: const TextStyle(color: kText2, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PieSection {
  final String label;
  final double value;
  final Color color;
  const _PieSection(this.label, this.value, this.color);
}
