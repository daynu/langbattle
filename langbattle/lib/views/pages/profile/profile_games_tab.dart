import 'package:flutter/material.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/profile/profile_widgets.dart';

class ProfileGamesTab extends StatefulWidget {
  final BattleService battleService;
  final List<GameRecord> allGames;
  final bool loading;
  final Map<String, String> flags;

  const ProfileGamesTab({
    super.key,
    required this.battleService,
    required this.allGames,
    required this.loading,
    required this.flags,
  });

  @override
  State<ProfileGamesTab> createState() => _ProfileGamesTabState();
}

class _ProfileGamesTabState extends State<ProfileGamesTab> {
  String? _filterLanguage;

  static const List<String> _languages = ['english', 'german', 'french'];

  List<GameRecord> get _filtered {
    if (_filterLanguage == null) return widget.allGames;
    return widget.allGames
        .where((g) => g.language == _filterLanguage)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myId = widget.battleService.currentUser?.userId ?? '';
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterLanguage == null,
                  onSelected: (_) =>
                      setState(() => _filterLanguage = null),
                ),
                const SizedBox(width: 8),
                ..._languages.map((lang) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Text(
                          widget.flags[lang] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                        label: Text(
                            lang[0].toUpperCase() + lang.substring(1)),
                        selected: _filterLanguage == lang,
                        onSelected: (_) =>
                            setState(() => _filterLanguage = lang),
                      ),
                    )),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No games found.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) => GameTileCompact(
                        game: filtered[index],
                        myId: myId,
                        flags: widget.flags,
                      ),
                    ),
        ),
      ],
    );
  }
}