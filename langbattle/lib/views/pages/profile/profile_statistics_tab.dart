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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TimeFilter.values.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
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
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: child),
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

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = widget.entries;

    final minY =
        (entries.map((e) => e.rating).reduce((a, b) => a < b ? a : b) - 50)
            .toDouble()
            .clamp(0.0, double.infinity);
    final maxY =
        entries
            .map((e) => e.rating)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() +
        50;
    final interval = ((maxY - minY) / 4).clamp(1.0, double.infinity);

    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.rating.toDouble()))
        .toList();

    return Container(
      height: 260,
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
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
                interval: interval,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
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
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
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
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: spot.x.toInt() == spots.length - 1 ? 4 : 5,
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
                    colorScheme.primary.withValues(alpha: 0.18),
                    colorScheme.primary.withValues(alpha: 0.0),
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
