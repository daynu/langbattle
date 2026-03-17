import 'dart:async';
import 'package:flutter/material.dart';
import 'package:langbattle/objects/game_record.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/profile/profile_friends_tab.dart';
import 'package:langbattle/views/pages/profile/profile_games_tab.dart';
import 'package:langbattle/views/pages/profile/profile_recap_tab.dart';
import 'package:langbattle/views/pages/profile/profile_statistics_tab.dart';
import 'package:langbattle/views/pages/settings_page.dart';
import 'package:langbattle/widgets/user_avatar.dart';

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
  StreamSubscription<Map<String, dynamic>>? _sub;
  List<GameRecord> _recentGames = [];
  List<GameRecord> _allGames = [];
  bool _gamesLoading = true;
  final _languageNotifier = ValueNotifier<String?>('german');

  static const Map<String, String> _flags = {
    'english': '🇬🇧',
    'german': '🇩🇪',
    'french': '🇫🇷',
    'romanian': '🇷🇴',
  };

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
      _languageNotifier.value = widget.initialStatisticsLanguage;
    }

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

      if (type == 'avatar_updated') {
          setState(() {});
        }
    });

    

    widget.battleService.requestFriendsList();
    widget.battleService.requestGameHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _languageNotifier.dispose();
    _sub?.cancel();
    super.dispose();
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
                _ProfileHeader(user: user, battleService: widget.battleService), // pass battleService
                TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Recap'),
                    Tab(text: 'Statistics'),
                    Tab(text: 'Games'),
                    Tab(text: 'Friends'),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ProfileRecapTab(
                        battleService: widget.battleService,
                        recentGames: _recentGames,
                        gamesLoading: _gamesLoading,
                        flags: _flags,
                        onLanguageTap: (lang) {
                          _languageNotifier.value = lang;
                          _tabController.animateTo(1);
                        },
                      ),
                      ProfileStatisticsTab(
                        battleService: widget.battleService,
                        languageNotifier: _languageNotifier,
                        flags: _flags,
                      ),
                      ProfileGamesTab(
                        battleService: widget.battleService,
                        allGames: _allGames,
                        loading: _gamesLoading,
                        flags: _flags,
                      ),
                      ProfileFriendsTab(
                          battleService: widget.battleService),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile header card
// ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserSession user;
  final BattleService battleService; // add this

  const _ProfileHeader({
    required this.user,
    required this.battleService, // add this
  });


  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Unknown';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 5) return 'Online';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }

  String _formatJoined(DateTime? createdAt) {
    if (createdAt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Joined ${months[createdAt.month - 1]} ${createdAt.year}';
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOnline = user.lastSeen != null &&
        DateTime.now().difference(user.lastSeen!).inMinutes < 5;
    final lastSeenText = _formatLastSeen(user.lastSeen);
    final joinedText = _formatJoined(user.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square profile picture with initials
              UserAvatar(
                name: user.name,
                base64Image: user.avatarBase64,
                size: 72,
                borderRadius: 12,
              ),

          const SizedBox(width: 14),

          // Name + info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                // Online / last seen
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? Colors.green.shade500
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lastSeenText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOnline
                            ? Colors.green.shade600
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Friends count
                Text(
                  '${user.friendsCount} ${user.friendsCount == 1 ? 'friend' : 'friends'}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),

                if (joinedText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    joinedText,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),

          // Edit button
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsPage(battleService: battleService)),
            ),
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit profile',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}