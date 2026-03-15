import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/welcome_page.dart';

// ─────────────────────────────────────────────
// Profile Page shell
// ─────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  final BattleService battleService;
  final String? initialStatisticsLanguage;

  const ProfilePage({
    super.key,
    required this.battleService,
    this.initialStatisticsLanguage,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  StreamSubscription<Map<String, dynamic>>? _sub;
  List<GameRecord> _recentGames = [];
  List<GameRecord> _allGames = [];
  bool _gamesLoading = true;
  final _statisticsLanguageNotifier = ValueNotifier<String?>('german');

  static const Map<String, String> _flags = {
    'english': '🇬🇧',
    'german': '🇩🇪',
    'french': '🇫🇷',
    'romanian': '🇷🇴',
  };

  // tabs: 0=Recap 1=Statistics 2=Games 3=Friends
  static const int _tabCount = 4;

  @override
  void initState() {
    super.initState();

    final initialIndex =
        widget.initialStatisticsLanguage != null ? 1 : 0;
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: initialIndex,
    );

    if (widget.initialStatisticsLanguage != null) {
      _statisticsLanguageNotifier.value = widget.initialStatisticsLanguage;
    }

    _nameController = TextEditingController(
      text: widget.battleService.currentUser?.name ?? '',
    );

    _sub = widget.battleService.stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];
      if (type == 'friends_list' ||
          type == 'friend_added' ||
          type == 'friend_removed' ||
          type == 'search_players_result') {
        setState(() {});
      }
      if (type == 'game_history') {
        final raw = event['games'] as List? ?? [];
        final parsed = raw
            .map((g) => GameRecord.fromJson(Map<String, dynamic>.from(g)))
            .toList();
        setState(() {
          _allGames = parsed;
          _recentGames = parsed.take(5).toList();
          _gamesLoading = false;
        });
      }
    });

    widget.battleService.requestFriendsList();
    widget.battleService.requestGameHistory();
  }

@override
void dispose() {
  _tabController.dispose();
  _nameController.dispose();
  _statisticsLanguageNotifier.dispose();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Log in to see your profile'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar + name
                _ProfileHeader(
                  nameController: _nameController,
                  onSave: _saveDisplayName,
                  user: user,
                ),

                // Tab bar — text only, sits flush below the header
                TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Recap'),
                    Tab(text: 'Statistics'),
                    Tab(text: 'Games'),
                    Tab(text: 'Friends'),
                  ],
                ),

                const Divider(height: 1),

                // Tab bodies
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _RecapTab(
                        battleService: widget.battleService,
                        recentGames: _recentGames,
                        gamesLoading: _gamesLoading,
                        flags: _flags,
                        onLanguageTap: (lang) {
                          _statisticsLanguageNotifier.value = lang;
                          _tabController.animateTo(1);
                        },
                      ),
                      _StatisticsTab(
                        battleService: widget.battleService,
                        languageNotifier: _statisticsLanguageNotifier,
                        flags: _flags,
                      ),
                      _GamesTab(
                        battleService: widget.battleService,
                        allGames: _allGames,
                        loading: _gamesLoading,
                        flags: _flags,
                      ),
                      _FriendsTab(battleService: widget.battleService),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile header
// ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onSave;
  final dynamic user;

  const _ProfileHeader({
    required this.nameController,
    required this.onSave,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            child: Icon(Icons.person, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onSave,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 0 — Recap
// ─────────────────────────────────────────────

class _RecapTab extends StatelessWidget {
  final BattleService battleService;
  final List<GameRecord> recentGames;
  final bool gamesLoading;
  final Map<String, String> flags;
  final void Function(String language) onLanguageTap;

  const _RecapTab({
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
          // Overall rating
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall ranking',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Rating: ${user.rating}',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Statistics tiles
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistics',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
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
                              color: colorScheme.outlineVariant,
                              width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Text(flags[entry.key] ?? '🌐',
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 6),
                            Text(
                              rating != null
                                  ? rating.toString()
                                  : '—',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500),
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

// ─────────────────────────────────────────────
// Tab 1 — Statistics
// ─────────────────────────────────────────────

enum _TimeFilter { week, month, threeMonths, year, allTime }

extension _TimeFilterExt on _TimeFilter {
  String get label {
    switch (this) {
      case _TimeFilter.week:        return '7d';
      case _TimeFilter.month:       return '30d';
      case _TimeFilter.threeMonths: return '90d';
      case _TimeFilter.year:        return '1y';
      case _TimeFilter.allTime:     return 'All';
    }
  }

  Duration? get duration {
    switch (this) {
      case _TimeFilter.week:        return const Duration(days: 7);
      case _TimeFilter.month:       return const Duration(days: 30);
      case _TimeFilter.threeMonths: return const Duration(days: 90);
      case _TimeFilter.year:        return const Duration(days: 365);
      case _TimeFilter.allTime:     return null;
    }
  }
}

class _RatingEntry {
  final DateTime date;
  final int rating;
  _RatingEntry(this.date, this.rating);
}

class _StatisticsTab extends StatefulWidget {
  final BattleService battleService;
  final ValueNotifier<String?> languageNotifier;
  final Map<String, String> flags;

  const _StatisticsTab({
    required this.battleService,
    required this.flags,
    required this.languageNotifier,
  });

  @override
  State<_StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<_StatisticsTab> {
  late String _selectedLanguage;
  _TimeFilter _filter = _TimeFilter.allTime;
  List<_RatingEntry> _allEntries = [];
  List<GameRecord> _languageGames = [];
  bool _loadingHistory = false;
  bool _loadingGames = false;
  StreamSubscription<Map<String, dynamic>>? _sub;

  static const List<String> _languages = ['english', 'german', 'french'];

  @override
  void initState() {
    super.initState();
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
            final date = DateTime.tryParse(
                    map['date']?.toString() ?? '') ??
                DateTime.now();
            final rating = (map['rating'] as num?)?.toInt() ?? 0;
            return _RatingEntry(date, rating);
          }).toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          _loadingHistory = false;
        });
      }
      if (event['type'] == 'game_history') {
        final raw = event['games'] as List? ?? [];
        setState(() {
          _languageGames = raw
              .map((g) =>
                  GameRecord.fromJson(Map<String, dynamic>.from(g)))
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

  List<_RatingEntry> get _filtered {
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
            initialValue: _selectedLanguage,
            key: ValueKey(_selectedLanguage), // force rebuild when language changes
            decoration: const InputDecoration(
              labelText: 'Language',
              border: OutlineInputBorder(),
            ),
            items: _languages.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Row(
                  children: [
                    Text(widget.flags[lang] ?? '🌐',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(lang[0].toUpperCase() + lang.substring(1)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v){
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
              children: _TimeFilter.values.map((f) {
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
            _emptyGraphBox(
              colorScheme,
              child: const CircularProgressIndicator(),
            )
          else if (!hasGraph)
            _emptyGraphBox(
              colorScheme,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 40, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text('No games in this period',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          else
            _EloChart(entries: filtered),

          const SizedBox(height: 16),

          if (hasGraph)
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Current',
                    value: (user.ratings[_selectedLanguage] ?? '—')
                        .toString(),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Peak',
                    value: _peakInPeriod?.toString() ?? '—',
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

          const SizedBox(height: 24),

          Text(
            'Recent ${_selectedLanguage[0].toUpperCase()}${_selectedLanguage.substring(1)} games',
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_loadingGames)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()))
          else if (_languageGames.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No games played in this language yet.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ..._languageGames.map((game) => _GameTileCompact(
                  game: game,
                  myId:
                      widget.battleService.currentUser?.userId ?? '',
                  flags: widget.flags,
                )),
        ],
      ),
    );
  }

  Widget _emptyGraphBox(ColorScheme cs, {required Widget child}) {
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

// ─────────────────────────────────────────────
// Tab 2 — Games
// ─────────────────────────────────────────────

class _GamesTab extends StatefulWidget {
  final BattleService battleService;
  final List<GameRecord> allGames;
  final bool loading;
  final Map<String, String> flags;

  const _GamesTab({
    required this.battleService,
    required this.allGames,
    required this.loading,
    required this.flags,
  });

  @override
  State<_GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<_GamesTab> {
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
        // Language filter chips
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
                        avatar: Text(widget.flags[lang] ?? '',
                            style: const TextStyle(fontSize: 14)),
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
                      itemBuilder: (context, index) => _GameTileCompact(
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

// ─────────────────────────────────────────────
// Tab 3 — Friends
// ─────────────────────────────────────────────

class _FriendsTab extends StatefulWidget {
  final BattleService battleService;
  const _FriendsTab({required this.battleService});

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  late TextEditingController _searchController;
  Timer? _debounce;
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _sub = widget.battleService.stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];
      if (type == 'friends_list' ||
          type == 'friend_added' ||
          type == 'friend_removed' ||
          type == 'search_players_result') {
        setState(() {});
      }
      if (type == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(event['message']?.toString() ??
                  'Something went wrong')),
        );
      }
    });
    widget.battleService.requestFriendsList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.battleService.searchPlayersByName(value.trim());
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final friends = widget.battleService.friends;
    final searchResults = widget.battleService.searchResults;
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search players by name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isSearching
                ? _buildSearchResults(searchResults, friends)
                : _buildFriendsList(friends),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      List<PlayerSearchResult> results, List<FriendInfo> friends) {
    if (results.isEmpty) {
      return const Center(
          child:
              Text('No players found.', textAlign: TextAlign.center));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final player = results[index];
        final isAlreadyFriend = player.isSelf ||
            friends.any((f) => f.userId == player.userId) ||
            player.isFriend;
        return ListTile(
          leading:
              const CircleAvatar(child: Icon(Icons.person)),
          title: Text(player.name),
          subtitle: Text('Rating: ${player.rating}'),
          trailing: player.isSelf
              ? const Text('You',
                  style: TextStyle(color: Colors.grey))
              : isAlreadyFriend
                  ? const Icon(Icons.check, color: Colors.green)
                  : TextButton(
                      onPressed: () => widget.battleService
                          .addFriendById(player.userId),
                      child: const Text('Add'),
                    ),
        );
      },
    );
  }

  Widget _buildFriendsList(List<FriendInfo> friends) {
    if (friends.isEmpty) {
      return const Center(
        child: Text(
          'No friends yet.\nSearch by name to add players.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      itemCount: friends.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return ListTile(
          leading:
              const CircleAvatar(child: Icon(Icons.person)),
          title: Text(friend.name),
          subtitle: Text('Rating: ${friend.rating}'),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle,
                color: Colors.red),
            onPressed: () =>
                widget.battleService.removeFriend(friend.userId),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// ELO Line Chart
// ─────────────────────────────────────────────

class _EloChart extends StatefulWidget {
  final List<_RatingEntry> entries;
  const _EloChart({required this.entries});

  @override
  State<_EloChart> createState() => _EloChartState();
}

class _EloChartState extends State<_EloChart> {
  int? _touchedIndex;

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = widget.entries;

    final minY = (entries
                .map((e) => e.rating)
                .reduce((a, b) => a < b ? a : b) -
            50)
        .toDouble()
        .clamp(0.0, double.infinity);
    final maxY = entries
            .map((e) => e.rating)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() +
        50;
    final interval =
        ((maxY - minY) / 4).clamp(1.0, double.infinity);

    final spots = entries
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), e.value.rating.toDouble()))
        .toList();

    return Container(
      height: 260,
      padding:
          const EdgeInsets.only(right: 16, top: 16, bottom: 8),
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
              color:
                  colorScheme.outlineVariant.withOpacity(0.5),
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
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (entries.length / 4)
                    .clamp(1.0, double.infinity),
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
                          color: colorScheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchCallback: (event, response) {
              setState(() {
                _touchedIndex =
                    response?.lineBarSpots?.first.x.toInt();
              });
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) =>
                  touchedSpots.map((s) {
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
                        color: colorScheme.onPrimaryContainer
                            .withOpacity(0.8),
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
                getDotPainter: (spot, _, __, ___) =>
                    FlDotCirclePainter(
                  radius: spot.x.toInt() == spots.length - 1
                      ? 4
                      : 5,
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

// ─────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: color)),
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
            const Text('Recent Games',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (loading)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: CircularProgressIndicator()))
            else if (games.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
                child: Text('No games played yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
              )
            else
              ...games.map((game) => _GameTileCompact(
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

class _GameTileCompact extends StatelessWidget {
  final GameRecord game;
  final String myId;
  final Map<String, String> flags;

  const _GameTileCompact(
      {required this.game,
      required this.myId,
      required this.flags});

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
    final flag = flags[game.language.toLowerCase()] ?? '🌐';

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
        delta >= 0 ? Colors.green.shade600 : colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opp.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('Rating: ${opp.ratingBefore}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${me.score} - ${opp.score}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(resultLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: resultColor,
                      fontWeight: FontWeight.w600)),
              Text(delta >= 0 ? '+$delta' : '$delta',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: deltaColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}