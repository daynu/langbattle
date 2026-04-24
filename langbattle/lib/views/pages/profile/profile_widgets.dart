import 'package:flutter/material.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/widgets/language_flag.dart';
import 'package:langbattle/widgets/user_avatar.dart';

class GameTileCompact extends StatelessWidget {
  final GameRecord game;
  final String myId;

  const GameTileCompact({super.key, required this.game, required this.myId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final me = game.myRecord(myId);
    final opp = game.opponentRecord(myId);
    if (me == null || opp == null) return const SizedBox.shrink();

    final won = game.didWin(myId);
    final draw = game.isDraw(myId);
    final delta = me.ratingAfter - me.ratingBefore;
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

    final deltaColor = delta >= 0 ? Colors.green.shade600 : colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          LanguageFlag(
            language: game.language,
            width: 38,
            height: 28,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  name: opp.name,
                  base64Image: opp.avatarBase64,
                  size: 32,
                  borderRadius: 6,
                ),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                resultLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: resultColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                delta >= 0 ? '+$delta' : '$delta',
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

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
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
