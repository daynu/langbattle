import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/profile/profile_widgets.dart';
import 'package:langbattle/widgets/language_flag.dart';

enum TimeFilter { week, month, threeMonths, year, allTime }

extension TimeFilterExt on TimeFilter {
  String get label {
    switch (this) {
      case TimeFilter.week:
        return '7d';
      case TimeFilter.month:
        return '30d';
      case TimeFilter.threeMonths:
        return '90d';
      case TimeFilter.year:
        return '1y';
      case TimeFilter.allTime:
        return 'All';
    }
  }

  Duration? get duration {
    switch (this) {
      case TimeFilter.week:
        return const Duration(days: 7);
      case TimeFilter.month:
        return const Duration(days: 30);
      case TimeFilter.threeMonths:
        return const Duration(days: 90);
      case TimeFilter.year:
        return const Duration(days: 365);
      case TimeFilter.allTime:
        return null;
    }
  }

  String get detail {
    switch (this) {
      case TimeFilter.week:
        return 'Last week';
      case TimeFilter.month:
        return 'Last month';
      case TimeFilter.threeMonths:
        return '3 months';
      case TimeFilter.year:
        return 'Past year';
      case TimeFilter.allTime:
        return 'History';
    }
  }
}

class RatingEntry {
  final DateTime date;
  final int rating;
  RatingEntry(this.date, this.rating);
}

class ProfileStatisticsTab extends StatefulWidget {
  final BattleService battleService;
  final ValueNotifier<String?> languageNotifier;

  const ProfileStatisticsTab({
    super.key,
    required this.battleService,
    required this.languageNotifier,
  });

  @override
  State<ProfileStatisticsTab> createState() => _ProfileStatisticsTabState();
}

class _ProfileStatisticsTabState extends State<ProfileStatisticsTab> {
  late String _selectedLanguage;
  TimeFilter _filter = TimeFilter.allTime;
  List<RatingEntry> _allEntries = [];
  List<GameRecord> _languageGames = [];
  bool _loadingHistory = false;
  bool _loadingGames = false;
  StreamSubscription<Map<String, dynamic>>? _sub;

  static const List<String> _languages = ['english', 'german', 'french'];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.languageNotifier.value ?? 'german';
    widget.languageNotifier.addListener(_onLanguageChanged);

    _sub = widget.battleService.stream.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'rating_history') {
        final lang = event['language']?.toString();
        if (lang != _selectedLanguage) return;
        final raw = event['history'] as List? ?? [];
        setState(() {
          _allEntries = raw.map((e) {
            final map = Map<String, dynamic>.from(e);
            final date =
                DateTime.tryParse(map['date']?.toString() ?? '') ??
                DateTime.now();
            final rating = (map['rating'] as num?)?.toInt() ?? 0;
            return RatingEntry(date, rating);
          }).toList()..sort((a, b) => a.date.compareTo(b.date));
          _loadingHistory = false;
        });
      }
      if (event['type'] == 'game_history') {
        final raw = event['games'] as List? ?? [];
        setState(() {
          _languageGames = raw
              .map((g) => GameRecord.fromJson(Map<String, dynamic>.from(g)))
              .where((g) => g.language == _selectedLanguage)
              .take(5)
              .toList();
          _loadingGames = false;
        });
      }
    });

    _fetchData();
  }

  void _onLanguageChanged() {
    final lang = widget.languageNotifier.value;
    if (lang != null && lang != _selectedLanguage) {
      setState(() => _selectedLanguage = lang);
      _fetchData();
    }
  }

  @override
  void dispose() {
    widget.languageNotifier.removeListener(_onLanguageChanged);
    _sub?.cancel();
    super.dispose();
  }

  void _fetchData() {
    setState(() {
      _loadingHistory = true;
      _loadingGames = true;
      _allEntries = [];
      _languageGames = [];
    });
    widget.battleService.requestRatingHistory(_selectedLanguage);
    widget.battleService.requestGameHistory();
  }

  List<RatingEntry> get _filtered {
    final dur = _filter.duration;
    if (dur == null) return _allEntries;
    final cutoff = DateTime.now().subtract(dur);
    return _allEntries.where((e) => e.date.isAfter(cutoff)).toList();
  }

  int? get _peakInPeriod {
    final f = _filtered;
    if (f.isEmpty) return null;
    return f.map((e) => e.rating).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filtered;
    final hasGraph = filtered.length >= 2;
    final user = widget.battleService.currentUser!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedLanguage),
            initialValue: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Language',
              border: OutlineInputBorder(),
            ),
            items: _languages.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Row(
                  children: [
                    LanguageFlag(
                      language: lang,
                      width: 30,
                      height: 22,
                      borderRadius: 6,
                    ),
                    const SizedBox(width: 8),
                    Text(lang[0].toUpperCase() + lang.substring(1)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null || v == _selectedLanguage) return;
              widget.languageNotifier.value = v;
              setState(() => _selectedLanguage = v);
              _fetchData();
            },
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1EC),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIME RANGE',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A5C58),
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TimeFilter.values.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _TimeRangeOption(
                          label: filter.label,
                          detail: filter.detail,
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_loadingHistory)
            _emptyBox(colorScheme, child: const CircularProgressIndicator())
          else if (!hasGraph)
            _emptyBox(
              colorScheme,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 40,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No games in this period',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            EloChart(entries: filtered),

          const SizedBox(height: 16),

          if (hasGraph)
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Current',
                    value: (user.ratings[_selectedLanguage] ?? '—').toString(),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Peak',
                    value: _peakInPeriod?.toString() ?? '—',
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Games',
                    value: (filtered.length - 1).toString(),
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          Text(
            'Recent ${_selectedLanguage[0].toUpperCase()}${_selectedLanguage.substring(1)} games',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_loadingGames)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_languageGames.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No games played in this language yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ..._languageGames.map(
              (game) => GameTileCompact(
                game: game,
                myId: widget.battleService.currentUser?.userId ?? '',
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyBox(ColorScheme cs, {required Widget child}) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE1E1DC)),
      ),
      child: Center(child: child),
    );
  }
}

class _TimeRangeOption extends StatelessWidget {
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  const _TimeRangeOption({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? const Color(0xFF553E00)
        : const Color(0xFF5A5C58);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minWidth: 86),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDC003) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFFDC003) : const Color(0xFFE1E1DC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: foreground.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EloChart extends StatefulWidget {
  final List<RatingEntry> entries;
  const EloChart({super.key, required this.entries});

  @override
  State<EloChart> createState() => _EloChartState();
}

class _EloChartState extends State<EloChart> {
  int? _touchedIndex;

  static const List<String> _monthLabels = [
    'jan.',
    'feb.',
    'mar.',
    'apr.',
    'may.',
    'jun.',
    'jul.',
    'aug.',
    'sep.',
    'oct.',
    'nov.',
    'dec.',
  ];

  String _formatDate(DateTime date) {
    final month = _monthLabels[date.month - 1];
    return '${date.day} $month ${date.year}.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = widget.entries;
    const chartLineColor = Color(0xFFFDC003);

    final minRating = entries
        .map((e) => e.rating)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
    final maxRating = entries
        .map((e) => e.rating)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    const yAxisStepCandidates = [50.0, 100.0, 250.0, 500.0, 1000.0, 2000.0];
    var yAxisInterval = yAxisStepCandidates.last;
    var minY = 0.0;
    var maxY = yAxisInterval * 2;

    for (final candidate in yAxisStepCandidates) {
      final adjustedMinRating = minRating == maxRating
          ? minRating - candidate
          : minRating;
      final lowerBound = (adjustedMinRating / candidate).floor() * candidate;
      final candidateMinY = lowerBound < 0 ? 0.0 : lowerBound;
      final candidateMaxY = candidateMinY + (candidate * 2);

      if (candidateMaxY >= maxRating) {
        yAxisInterval = candidate;
        minY = candidateMinY;
        maxY = candidateMaxY;
        break;
      }
    }
    final yAxisValues = [minY, minY + yAxisInterval, maxY];
    bool shouldShowYAxisValue(double value) {
      return yAxisValues.any((axisValue) => (axisValue - value).abs() < 0.01);
    }

    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.rating.toDouble()))
        .toList();

    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(14, 18, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE1E1DC)),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yAxisInterval,
            checkToShowHorizontalLine: shouldShowYAxisValue,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: const Color(0xFFE1E1DC), strokeWidth: 0.8),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: yAxisInterval,
                getTitlesWidget: (value, _) {
                  if (!shouldShowYAxisValue(value)) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Color(0xFF5A5C58),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: (entries.length / 4).clamp(1.0, double.infinity),
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _formatDate(entries[idx].date),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        color: Color(0xFF5A5C58),
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineTouchData: LineTouchData(
            touchCallback: (event, response) {
              setState(() {
                _touchedIndex = response?.lineBarSpots?.first.x.toInt();
              });
            },
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((_) {
                return TouchedSpotIndicatorData(
                  const FlLine(color: Colors.transparent, strokeWidth: 0),
                  FlDotData(show: false),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                final idx = s.x.toInt();
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
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
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
              color: chartLineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot.x.toInt() == _touchedIndex,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 5,
                  color: chartLineColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    chartLineColor.withValues(alpha: 0.16),
                    chartLineColor.withValues(alpha: 0.0),
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
