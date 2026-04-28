import 'package:flutter/material.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/profile/profile_widgets.dart';
import 'package:langbattle/widgets/language_flag.dart';

class ProfileRecapTab extends StatelessWidget {
  final BattleService battleService;
  final List<GameRecord> recentGames;
  final bool gamesLoading;
  final void Function(String language) onLanguageTap;

  const ProfileRecapTab({
    super.key,
    required this.battleService,
    required this.recentGames,
    required this.gamesLoading,
    required this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = battleService.currentUser!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1EC),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LANGUAGE RATINGS',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A5C58),
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: user.ratings.entries.map((entry) {
                      final rating = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => onLanguageTap(entry.key),
                          child: Container(
                            width: 124,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE1E1DC),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LanguageFlag(
                                  language: entry.key,
                                  width: 48,
                                  height: 34,
                                  borderRadius: 10,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  rating != null ? rating.toString() : 'N/A',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2D2F2C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.key[0].toUpperCase() +
                                      entry.key.substring(1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5A5C58),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _RecentGamesCard(
            battleService: battleService,
            games: recentGames,
            loading: gamesLoading,
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

  const _RecentGamesCard({
    required this.battleService,
    required this.games,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = battleService.currentUser?.userId ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE1E1DC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RECENT GAMES',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A5C58),
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
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
                    color: const Color(0xFF5A5C58),
                  ),
                ),
              )
            else
              ...games.map((game) => GameTileCompact(game: game, myId: myId)),
          ],
        ),
      ),
    );
  }
}
