import 'dart:async';
import 'package:flutter/material.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/friends_page.dart';
import 'package:langbattle/views/pages/game_history_page.dart';
import 'package:langbattle/views/pages/welcome_page.dart';

class ProfilePage extends StatefulWidget {
  final BattleService battleService;

  const ProfilePage({
    super.key,
    required this.battleService,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  StreamSubscription<Map<String, dynamic>>? _sub;
  List<GameRecord> _recentGames = [];
  bool _gamesLoading = true;

  static const Map<String, String> _languageFlags = {
    'english': '🇬🇧',
    'german': '🇩🇪',
    'french': '🇫🇷',
    'romanian': '🇷🇴',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.battleService.currentUser?.name ?? '',
    );

    _sub = widget.battleService.stream.listen((event) {
      final type = event['type'];
      if (!mounted) return;
      if (type == 'friends_list' || type == 'friend_added') {
        setState(() {});
      }
      if (type == 'game_history') {
        final raw = event['games'] as List? ?? [];
        setState(() {
          _recentGames = raw
              .take(5)
              .map((g) => GameRecord.fromJson(Map<String, dynamic>.from(g)))
              .toList();
          _gamesLoading = false;
        });
      }
    });

    widget.battleService.requestFriendsList();
    widget.battleService.requestGameHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _saveDisplayName() {
    final user = widget.battleService.currentUser;
    final newName = _nameController.text.trim();
    if (user == null || newName.isEmpty || newName == user.name) return;
    widget.battleService.currentUser = user.copyWith(name: newName);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.battleService.currentUser;
    final friendsCount =
        user?.friendsCount ?? widget.battleService.friends.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Log in to see your profile'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar + name
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        child: Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: _saveDisplayName,
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Overall ranking
              
                  // Statistics
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: user.ratings.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _languageFlags[entry.key] ?? '🌐',
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.key[0].toUpperCase() + entry.key.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),

                  const SizedBox(height: 16),

                  // Recent games
                  _RecentGamesSection(
                    battleService: widget.battleService,
                    games: _recentGames,
                    loading: _gamesLoading,
                  ),

                  const SizedBox(height: 16),

                  // Friends
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FriendsPage(
                              battleService: widget.battleService),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Friends',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              friendsCount == 1
                                  ? 'You have 1 friend connected.'
                                  : 'You have $friendsCount friends connected.',
                            ),
                            const SizedBox(height: 4),
                            const Text(
                                'Tap to view your friends and add new ones.'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      widget.battleService.logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => WelcomePage()),
                      );
                    },
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _RecentGamesSection extends StatelessWidget {
  final BattleService battleService;
  final List<GameRecord> games;
  final bool loading;

  static const Map<String, String> _languageFlags = {
    'english': '🇬🇧',
    'german': '🇩🇪',
    'french': '🇫🇷',
    'romanian': '🇷🇴',
  };

  const _RecentGamesSection({
    required this.battleService,
    required this.games,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myId = battleService.currentUser?.userId ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Games',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!loading)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameHistoryPage(
                          battleService: battleService,
                          initialGames: games,
                        ),
                      ),
                    ),
                    child: const Text('See all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (games.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No games played yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...games.map((game) {
                final me = game.myRecord(myId);
                final opp = game.opponentRecord(myId);
                if (me == null || opp == null) return const SizedBox.shrink();

                final won = game.didWin(myId);
                final draw = game.isDraw(myId);
                final ratingDelta = me.ratingAfter - me.ratingBefore;
                final flag =
                    _languageFlags[game.language.toLowerCase()] ?? '🌐';

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

                final deltaColor = ratingDelta >= 0
                    ? Colors.green.shade600
                    : colorScheme.error;
                final deltaText =
                    ratingDelta >= 0 ? '+$ratingDelta' : '$ratingDelta';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opp.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Rating: ${opp.ratingBefore}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${me.score} - ${opp.score}',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            resultLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: resultColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
              }),
          ],
        ),
      ),
    );
  }
}