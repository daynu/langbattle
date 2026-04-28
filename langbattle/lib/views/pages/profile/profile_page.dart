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

  static const int _tabCount = 4;
  static const _background = Color(0xFFF7F7F2);
  static const _onBackground = Color(0xFF2D2F2C);
  static const _onSurfaceVariant = Color(0xFF5A5C58);
  static const _surfaceContainerLow = Color(0xFFF1F1EC);
  static const _primaryContainer = Color(0xFFFDC003);
  static const _onPrimaryContainer = Color(0xFF553E00);

  @override
  void initState() {
    super.initState();

    final initialIndex = widget.initialStatisticsLanguage != null ? 1 : 0;
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
          type == 'search_players_result' ||
          type == 'auth_success') {
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
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: user == null
            ? const Center(child: Text('Log in to see your profile'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    child: Row(
                      children: [
                        _HeaderIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Profile',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: _onPrimaryContainer,
                            ),
                          ),
                        ),
                        _HeaderIconButton(
                          icon: Icons.settings_outlined,
                          tooltip: 'Settings',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsPage(
                                battleService: widget.battleService,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ProfileHeader(user: user),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: _primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelColor: _onPrimaryContainer,
                        unselectedLabelColor: _onSurfaceVariant,
                        labelStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        tabs: const [
                          Tab(text: 'Recap'),
                          Tab(text: 'Stats'),
                          Tab(text: 'Games'),
                          Tab(text: 'Friends'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ProfileRecapTab(
                          battleService: widget.battleService,
                          recentGames: _recentGames,
                          gamesLoading: _gamesLoading,
                          onLanguageTap: (lang) {
                            _languageNotifier.value = lang;
                            _tabController.animateTo(1);
                          },
                        ),
                        ProfileStatisticsTab(
                          battleService: widget.battleService,
                          languageNotifier: _languageNotifier,
                        ),
                        ProfileGamesTab(
                          battleService: widget.battleService,
                          allGames: _allGames,
                          loading: _gamesLoading,
                        ),
                        ProfileFriendsTab(battleService: widget.battleService),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile header card
// ─────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _ProfilePageState._surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _ProfilePageState._onPrimaryContainer),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserSession user;

  const _ProfileHeader({required this.user});

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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Joined ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isOnline =
        user.lastSeen != null &&
        DateTime.now().difference(user.lastSeen!).inMinutes < 5;
    final lastSeenText = _formatLastSeen(user.lastSeen);
    final joinedText = _formatJoined(user.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D2F2C).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF755700).withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: UserAvatar(
                      name: user.name,
                      base64Image: user.avatarBase64,
                      size: 72,
                      borderRadius: 22,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF0D6661)
                          : _ProfilePageState._onSurfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: _ProfilePageState._onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ProfileInfoPill(
                        icon: Icons.circle,
                        label: lastSeenText,
                        color: isOnline
                            ? const Color(0xFF0D6661)
                            : _ProfilePageState._onSurfaceVariant,
                      ),
                      _ProfileInfoPill(
                        icon: Icons.group_outlined,
                        label:
                            '${user.friendsCount} ${user.friendsCount == 1 ? 'friend' : 'friends'}',
                        color: _ProfilePageState._onSurfaceVariant,
                      ),
                      if (joinedText.isNotEmpty)
                        _ProfileInfoPill(
                          icon: Icons.calendar_today_outlined,
                          label: joinedText,
                          color: _ProfilePageState._onSurfaceVariant,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProfileInfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _ProfilePageState._surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: icon == Icons.circle ? 8 : 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: _ProfilePageState._onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
