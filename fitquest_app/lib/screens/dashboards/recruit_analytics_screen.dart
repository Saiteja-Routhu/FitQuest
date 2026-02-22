import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart';
import '../../services/analytics_service.dart';

class RecruitAnalyticsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const RecruitAnalyticsScreen({
    super.key,
    required this.userData,
    required this.password,
  });

  @override
  State<RecruitAnalyticsScreen> createState() => _RecruitAnalyticsScreenState();
}

class _RecruitAnalyticsScreenState extends State<RecruitAnalyticsScreen> {
  List<dynamic> _bodyProgress = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final data = await AnalyticsService.fetchBodyProgress(
          widget.userData['username'] ?? '', widget.password);
      if (mounted) setState(() { _bodyProgress = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Extract weight entries for line chart
  List<FlSpot> _weightSpots() {
    final sorted = List<dynamic>.from(_bodyProgress)
      ..sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
    return List.generate(sorted.length, (i) {
      final w = (sorted[i]['weight_kg'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(i.toDouble(), w);
    });
  }

  double _latestWeight() {
    if (_bodyProgress.isEmpty) return 0;
    return (_bodyProgress.last['weight_kg'] as num?)?.toDouble() ?? 0;
  }

  double _latestBodyFat() {
    if (_bodyProgress.isEmpty) return 0;
    return (_bodyProgress.last['body_fat_estimate'] as num?)?.toDouble() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('ANALYTICS', style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FQColors.border, height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FQColors.cyan))
          : _bodyProgress.isEmpty
              ? _emptyState()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _sectionLabel('CURRENT STATS'),
                    const SizedBox(height: 12),
                    _statCardsRow(),
                    const SizedBox(height: 24),
                    _sectionLabel('PERFORMANCE RADAR'),
                    const SizedBox(height: 12),
                    _radarChart(),
                    const SizedBox(height: 24),
                    _sectionLabel('WEIGHT OVER TIME'),
                    const SizedBox(height: 12),
                    _weightLineChart(),
                    const SizedBox(height: 24),
                    _sectionLabel('BODY SCAN HISTORY'),
                    const SizedBox(height: 12),
                    ..._bodyProgress.reversed.map((e) => _progressCard(e)),
                  ],
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.bar_chart_outlined, color: FQColors.muted, size: 64),
        const SizedBox(height: 16),
        Text('No Progress Data Yet', style: GoogleFonts.rajdhani(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Complete a Body Scan to track your progress.',
            style: const TextStyle(color: FQColors.muted, fontSize: 13)),
      ]),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: GoogleFonts.rajdhani(
        color: FQColors.muted, fontSize: 11, letterSpacing: 2,
        fontWeight: FontWeight.w600));
  }

  Widget _statCardsRow() {
    final stats = [
      _StatItem('WEIGHT', '${_latestWeight().toStringAsFixed(1)} kg', FQColors.cyan),
      _StatItem('BODY FAT', '${_latestBodyFat().toStringAsFixed(1)}%', FQColors.purple),
      _StatItem('SCANS', '${_bodyProgress.length}', FQColors.gold),
    ];
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _statCard(stats[i]),
      ),
    );
  }

  Widget _statCard(_StatItem s) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.label, style: GoogleFonts.rajdhani(
            color: FQColors.muted, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(s.value, style: GoogleFonts.rajdhani(
            color: s.color, fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _radarChart() {
    // Decorative radar — 5 axes seeded from available data
    final xp = (widget.userData['xp'] as num?)?.toDouble() ?? 0;
    final level = (widget.userData['level'] as num?)?.toDouble() ?? 1;
    final normalize = (double v, double max) => (v / max).clamp(0.0, 1.0) * 4;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FQColors.border),
      ),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 8),
          gridBorderData: BorderSide(color: FQColors.border, width: 1),
          radarBorderData: BorderSide(color: FQColors.muted.withOpacity(0.3)),
          titleTextStyle: GoogleFonts.rajdhani(
              color: FQColors.muted, fontSize: 10, fontWeight: FontWeight.w600),
          dataSets: [
            RadarDataSet(
              dataEntries: [
                RadarEntry(value: normalize(level * 50, 100)),   // Strength
                RadarEntry(value: normalize(_bodyProgress.length * 40.0, 100)), // Cardio
                RadarEntry(value: normalize(2.5, 4)),             // Flexibility (static)
                RadarEntry(value: normalize(xp % 500 / 5, 100)), // Nutrition
                RadarEntry(value: normalize(3.0, 4)),             // Recovery (static)
              ],
              fillColor: FQColors.cyan.withOpacity(0.15),
              borderColor: FQColors.cyan,
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
          getTitle: (index, _) {
            const titles = ['Strength', 'Cardio', 'Flex', 'Nutrition', 'Recovery'];
            return RadarChartTitle(text: titles[index], angle: 0);
          },
        ),
      ),
    );
  }

  Widget _weightLineChart() {
    final spots = _weightSpots();
    if (spots.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FQColors.border),
        ),
        child: Center(child: Text('Not enough data',
            style: TextStyle(color: FQColors.muted))),
      );
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FQColors.border),
      ),
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: FQColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(0),
                  style: const TextStyle(color: FQColors.muted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: spots.length <= 8,
                getTitlesWidget: (v, _) => Text(
                  '${(v + 1).toInt()}',
                  style: const TextStyle(color: FQColors.muted, fontSize: 9),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: FQColors.cyan,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: FQColors.cyan,
                  strokeWidth: 1,
                  strokeColor: FQColors.bg,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: FQColors.cyan.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCard(dynamic entry) {
    final e = entry as Map<String, dynamic>;
    final date = e['date']?.toString() ?? '';
    final weight = (e['weight_kg'] as num?)?.toStringAsFixed(1) ?? '—';
    final bf = (e['body_fat_estimate'] as num?)?.toStringAsFixed(1) ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FQColors.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FQColors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.accessibility_new_outlined,
              color: FQColors.cyan, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(date, style: GoogleFonts.rajdhani(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Row(children: [
              _badge('$weight kg', FQColors.cyan),
              const SizedBox(width: 8),
              _badge('$bf% BF', FQColors.purple),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}
