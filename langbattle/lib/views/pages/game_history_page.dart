import 'dart:async';
import 'package:flutter/material.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/services/web-socket.dart';

class GameHistoryPage extends StatefulWidget {
  final BattleService battleService;
  final List<GameRecord> initialGames;

  const GameHistoryPage({
    super.key,
    required this.battleService,
    required this.initialGames,
  });

  @override
  State<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends State<GameHistoryPage> {
  List<GameRecord> _games = [];
  String? _selectedLanguage; // null = all
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _loading = false;

  static const Map<String, String> _languageFlags = {
    'english': '🇬🇧',
    'german': '🇩🇪',
    'french': '🇫🇷',
    'romanian': '🇷🇴',
  };

  static const List<String> _languages = ['english', 'german', 'french'];

  @override
  void initState() {
    super.initState();
    _games = List.from(widget.initialGames);

    _sub = widget.battleService.stream.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'game_history') {
        final raw = event['games'] as List? ?? [];
        setState(() {
          _games = raw
              .map((g) => GameRecord.fromJson(Map<String, dynamic>.from(g)))
              .toList();
          _loading = false;
        });
      }
    });

    // If we have no initial games, fetch all
    if (_games.isEmpty) _fetchHistory();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _fetchHistory() {
    setState(() => _loading = true);
    widget.battleService.requestGameHistory();
  }

  List<GameRecord> get _filtered {
    if (_selectedLanguage == null) return _games;
    return _games.where((g) => g.language == _selectedLanguage).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myId = widget.battleService.currentUser?.userId ?? '';
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
      ),
      body: Column(
        children: [
          // Language filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedLanguage == null,
                    onSelected: (_) => setState(() => _selectedLanguage = null),
                  ),
                  const SizedBox(width: 8),
                  ..._languages.map((lang) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Text(
                            _languageFlags[lang] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          label: Text(
                            lang[0].toUpperCase() + lang.substring(1),
                          ),
                          selected: _selectedLanguage == lang,
                          onSelected: (_) =>
                              setState(() => _selectedLanguage = lang),
                        ),
                      )),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Game list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No games found.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          return _GameTile(
                            game: filtered[index],
                            myId: myId,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final GameRecord game;
  final String myId;

  static const Map<String, String> _languageFlags = {
    'english': '🇬🇧',
    'german': '🇩🇪',
    'french': '🇫🇷',
    'romanian': '🇷🇴',
  };

  const _GameTile({required this.game, required this.myId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final me = game.myRecord(myId);
    final opp = game.opponentRecord(myId);

    if (me == null || opp == null) return const SizedBox.shrink();

    final won = game.didWin(myId);
    final draw = game.isDraw(myId);
    final ratingDelta = me.ratingAfter - me.ratingBefore;
    final flag = _languageFlags[game.language.toLowerCase()] ?? '🌐';

    Color resultColor;
    String resultLabel;
    if (draw) {
      resultColor = colorScheme.onSurfaceVariant;
      resultLabel = 'Draw';
    } else if (won) {
      resultColor = Colors.green.shade600;
      resultLabel = 'Win';
    } else {
      resultColor = colorScheme.error;
      resultLabel = 'Loss';
    }

    final deltaColor =
        ratingDelta >= 0 ? Colors.green.shade600 : colorScheme.error;
    final deltaText =
        ratingDelta >= 0 ? '+$ratingDelta' : '$ratingDelta';

    // Format date
    final now = DateTime.now();
    final diff = now.difference(game.playedAt);
    String dateLabel;
    if (diff.inMinutes < 60) {
      dateLabel = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      dateLabel = '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      dateLabel = '${diff.inDays}d ago';
    } else {
      dateLabel =
          '${game.playedAt.day}/${game.playedAt.month}/${game.playedAt.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Flag
          Text(flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),

          // Opponent name + rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opp.name,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${game.language[0].toUpperCase()}${game.language.substring(1)} • ${game.level} • $dateLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rating: ${opp.ratingBefore}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Score + result + delta
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${me.score} - ${opp.score}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                resultLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: resultColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                deltaText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: deltaColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}