import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:langbattle/services/web-socket.dart';

class RatingHistoryPage extends StatefulWidget {
  final BattleService battleService;
  final String language;
  final String languageLabel;
  final String flag;

  const RatingHistoryPage({
    super.key,
    required this.battleService,
    required this.language,
    required this.languageLabel,
    required this.flag,
  });

  @override
  State<RatingHistoryPage> createState() => _RatingHistoryPageState();
}

enum _TimeFilter { week, month, threeMonths, year, allTime }

extension _TimeFilterLabel on _TimeFilter {
  String get label {
    switch (this) {
      case _TimeFilter.week:
        return '7d';
      case _TimeFilter.month:
        return '30d';
      case _TimeFilter.threeMonths:
        return '90d';
      case _TimeFilter.year:
        return '1y';
      case _TimeFilter.allTime:
        return 'All';
    }
  }

  Duration? get duration {
    switch (this) {
      case _TimeFilter.week:
        return const Duration(days: 7);
      case _TimeFilter.month:
        return const Duration(days: 30);
      case _TimeFilter.threeMonths:
        return const Duration(days: 90);
      case _TimeFilter.year:
        return const Duration(days: 365);
      case _TimeFilter.allTime:
        return null;
    }
  }
}

class _RatingEntry {
  final DateTime date;
  final int rating;
  _RatingEntry(this.date, this.rating);
}

class _RatingHistoryPageState extends State<RatingHistoryPage> {
  List<_RatingEntry> _allEntries = [];
  _TimeFilter _filter = _TimeFilter.allTime;
  bool _loading = true;
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.battleService.stream.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'rating_history') {
        final lang = event['language']?.toString();
        if (lang != widget.language) return;
        final raw = event['history'] as List? ?? [];
        setState(() {
          _allEntries = raw.map((e) {
            final map = Map<String, dynamic>.from(e);
            final date = DateTime.tryParse(map['date']?.toString() ?? '') ??
                DateTime.now();
            final rating = (map['rating'] as num?)?.toInt() ?? 0;
            return _RatingEntry(date, rating);
          }).toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          _loading = false;
        });
      }
    });

    widget.battleService.requestRatingHistory(widget.language);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<_RatingEntry> get _filtered {
    final dur = _filter.duration;
    if (dur == null) return _allEntries;
    final cutoff = DateTime.now().subtract(dur);
    return _allEntries.where((e) => e.date.isAfter(cutoff)).toList();
  }

  int? get _highestInPeriod {
    final f = _filtered;
    if (f.isEmpty) return null;
    return f.map((e) => e.rating).reduce((a, b) => a > b ? a : b);
  }

  int? get _currentRating {
    final f = _filtered;
    if (f.isEmpty) return null;
    return f.last.rating;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filtered;
    final hasData = filtered.length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('${widget.languageLabel} Rating'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _TimeFilter.values.map((f) {
                        final selected = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f.label),
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Graph or empty state
                  if (!hasData)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart_rounded,
                                size: 40,
                                color: colorScheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              'No games in this period',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _EloChart(entries: filtered),

                  const SizedBox(height: 24),

                  // Stats row
                  if (hasData) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Current',
                            value: _currentRating.toString(),
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Peak in period',
                            value: _highestInPeriod.toString(),
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Games',
                            value: (filtered.length - 1).toString(),
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _EloChart extends StatefulWidget {
  final List<_RatingEntry> entries;
  const _EloChart({required this.entries});

  @override
  State<_EloChart> createState() => _EloChartState();
}

class _EloChartState extends State<_EloChart> {
  int? _touchedIndex;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = widget.entries;

    final minY = (entries.map((e) => e.rating).reduce((a, b) => a < b ? a : b) - 50)
        .toDouble()
        .clamp(0, double.infinity);
    final maxY = (entries.map((e) => e.rating).reduce((a, b) => a > b ? a : b) + 50)
        .toDouble();

    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.rating.toDouble());
    }).toList();

    return Container(
      height: 260,
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          minY: minY.toDouble(),
          maxY: maxY.toDouble(),
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(1, double.infinity),
            getDrawingHorizontalLine: (_) => FlLine(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: ((maxY - minY) / 4).clamp(1, double.infinity),
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (entries.length / 4).clamp(1, double.infinity),
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _formatDate(entries[idx].date),
                      style: TextStyle(
                          fontSize: 10, color: colorScheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchCallback: (event, response) {
              setState(() {
                _touchedIndex =
                    response?.lineBarSpots?.first.spotIndex;
              });
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.spotIndex;
                final entry = entries[idx];
                return LineTooltipItem(
                  '${entry.rating}\n',
                  TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: _formatDate(entry.date),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: colorScheme.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) =>
                    spot.x.toInt() == _touchedIndex ||
                    spot.x.toInt() == spots.length - 1,
                getDotPainter: (spot, _, __, idx) => FlDotCirclePainter(
                  radius: idx == spots.length - 1 ? 4 : 5,
                  color: colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withOpacity(0.18),
                    colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}