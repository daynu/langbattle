import 'package:flutter/material.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/profile/profile_widgets.dart';
import 'package:langbattle/views/pages/welcome_page.dart';

class ProfileRecapTab extends StatelessWidget {
  final BattleService battleService;
  final List<GameRecord> recentGames;
  final bool gamesLoading;
  final Map<String, String> flags;
  final void Function(String language) onLanguageTap;

  const ProfileRecapTab({
    super.key,
    required this.battleService,
    required this.recentGames,
    required this.gamesLoading,
    required this.flags,
    required this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = battleService.currentUser!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Statistics tiles
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
                  final rating = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => onLanguageTap(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colorScheme.outlineVariant, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Text(flags[entry.key] ?? '🌐',
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 6),
                            Text(
                              rating != null ? rating.toString() : '—',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.key[0].toUpperCase() +
                                  entry.key.substring(1),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Recent games
          _RecentGamesCard(
            battleService: battleService,
            games: recentGames,
            loading: gamesLoading,
            flags: flags,
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              battleService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => WelcomePage()),
              );
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _RecentGamesCard extends StatelessWidget {
  final BattleService battleService;
  final List<GameRecord> games;
  final bool loading;
  final Map<String, String> flags;

  const _RecentGamesCard({
    required this.battleService,
    required this.games,
    required this.loading,
    required this.flags,
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
            const Text(
              'Recent Games',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              ...games.map((game) => GameTileCompact(
                    game: game,
                    myId: myId,
                    flags: flags,
                  )),
          ],
        ),
      ),
    );
  }
}