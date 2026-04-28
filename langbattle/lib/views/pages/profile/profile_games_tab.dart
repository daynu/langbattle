import 'package:flutter/material.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/profile/profile_widgets.dart';
import 'package:langbattle/widgets/language_flag.dart';

class ProfileGamesTab extends StatefulWidget {
  final BattleService battleService;
  final List<GameRecord> allGames;
  final bool loading;

  const ProfileGamesTab({
    super.key,
    required this.battleService,
    required this.allGames,
    required this.loading,
  });

  @override
  State<ProfileGamesTab> createState() => _ProfileGamesTabState();
}

class _ProfileGamesTabState extends State<ProfileGamesTab> {
  String? _filterLanguage;

  static const List<String> _languageOrder = [
    'english',
    'german',
    'french',
    'romanian',
  ];

  List<GameRecord> get _filtered {
    if (_filterLanguage == null) return widget.allGames;
    return widget.allGames.where((g) => g.language == _filterLanguage).toList();
  }

  List<String> get _availableLanguages {
    final languages = <String>{
      ...?widget.battleService.currentUser?.ratings.keys,
      ...widget.allGames.map((g) => g.language),
    };

    final ordered = _languageOrder
        .where(languages.contains)
        .followedBy(
          languages.where((language) => !_languageOrder.contains(language)),
        )
        .toList();
    return ordered;
  }

  @override
  void didUpdateWidget(covariant ProfileGamesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_filterLanguage != null &&
        !_availableLanguages.contains(_filterLanguage)) {
      _filterLanguage = null;
    }
  }

  String _languageLabel(String language) {
    return language[0].toUpperCase() + language.substring(1);
  }

  int _countFor(String? language) {
    if (language == null) return widget.allGames.length;
    return widget.allGames.where((g) => g.language == language).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myId = widget.battleService.currentUser?.userId ?? '';
    final filtered = _filtered;
    final languages = _availableLanguages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1EC),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FILTER BY LANGUAGE',
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
                    children: [
                      _LanguageFilterOption(
                        label: 'All',
                        count: _countFor(null),
                        selected: _filterLanguage == null,
                        onTap: () => setState(() => _filterLanguage = null),
                      ),
                      const SizedBox(width: 10),
                      ...languages.map(
                        (language) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _LanguageFilterOption(
                            label: _languageLabel(language),
                            count: _countFor(language),
                            language: language,
                            selected: _filterLanguage == language,
                            onTap: () =>
                                setState(() => _filterLanguage = language),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: widget.loading
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
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (context, index) =>
                      GameTileCompact(game: filtered[index], myId: myId),
                ),
        ),
      ],
    );
  }
}

class _LanguageFilterOption extends StatelessWidget {
  final String label;
  final int count;
  final String? language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageFilterOption({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.language,
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
        constraints: const BoxConstraints(minWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDC003) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFFDC003) : const Color(0xFFE1E1DC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (language != null) ...[
              LanguageFlag(
                language: language!,
                width: 28,
                height: 20,
                borderRadius: 6,
              ),
              const SizedBox(width: 8),
            ] else ...[
              Icon(Icons.grid_view_rounded, size: 18, color: foreground),
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$count games',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: foreground.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
