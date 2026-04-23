import "package:flutter/material.dart";
import 'package:langbattle/views/pages/settings_page.dart';
import 'package:langbattle/data/notifiers.dart';
import 'dart:async';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/battle_page.dart';
import 'package:langbattle/views/pages/profile/profile_page.dart';
import 'package:langbattle/views/pages/notifications_page.dart';
import 'package:langbattle/views/pages/word_chain_battle_page.dart';
import 'package:langbattle/widgets/user_avatar.dart';
import 'package:langbattle/extensions/context_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langbattle/data/constants.dart';

class HomePage extends StatefulWidget {
  final BattleService battleService;
  const HomePage({super.key, required this.battleService});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double imgSize = 200;
  String selectedLanguage = "english";
  StreamSubscription<Map<String, dynamic>>? _sub;
  String selectedMode = "classic";

  final List<Map<String, String>> modes = [
    {"key": "classic", "title": "Classic", "icon": "🎯"},
    {"key": "word_chain", "title": "Word Chain", "icon": "🔗"},
  ];

  static const Map<String, String> languageLabels = {
    "english": "languageEnglish",
    "german": "languageGerman",
    "french": "languageFrench",
    "romanian": "languageRomanian",
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _sub = widget.battleService.stream.listen((event) {
      final type = event["type"];
      if (!mounted) return;
      if (type == "friend_requests" ||
          type == "friend_request_created" ||
          type == "friend_request_updated" ||
          type == "friend_added" ||
          type == "active_room" ||
          type == "online_count") {
        setState(() {});
      }
    });
    widget.battleService.requestFriendRequests();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Widget _buildActiveGameBanner(BuildContext context) {
    final room = widget.battleService.activeRoom!;
    final opponentName = room["opponentName"] ?? "Opponent";
    final myScore = room["myScore"] ?? 0;
    final opponentScore = room["opponentScore"] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.sports_kabaddi,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Game in progress",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "vs $opponentName  •  $myScore – $opponentScore",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _rejoinGame(context, room),
            child: const Text("Rejoin"),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mode = modes[index];
          final isSelected = selectedMode == mode["key"];

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedMode = mode["key"]!;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFDC003)
                      : const Color(0xFFE0E0DC),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFFFDC003).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode["icon"]!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    mode["title"]!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _rejoinGame(BuildContext context, Map<String, dynamic> room) {
    widget.battleService.rejoinRoom(room["roomId"]);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _buildBattleScreen(
          language: room["language"] ?? "english",
          mode: room["mode"] ?? "classic",
          restoredRoom: room,
        ),
      ),
    ).then((_) {
      // Clear the active room banner once they return from the game
      widget.battleService.activeRoom = null;
      setState(() {});
    });
  }

  Widget _buildBattleScreen({
    required String language,
    required String mode,
    Map<String, dynamic>? restoredRoom,
  }) {
    if (mode == "word_chain") {
      return WordChainBattleScreen(
        battleService: widget.battleService,
        language: language,
        restoredRoom: restoredRoom,
      );
    }

    return BattleScreen(
      battleService: widget.battleService,
      language: language,
      restoredRoom: restoredRoom,
      mode: mode,
    );
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(Kconstants.battleLanguageKey);
    final uiLocale = localeNotifier.value?.languageCode ?? 'en';
    final localeMap = {
      'english': 'en',
      'german': 'de',
      'french': 'fr',
      'romanian': 'ro',
    };
    if (saved != null &&
        languageLabels.containsKey(saved) &&
        localeMap[saved] != uiLocale) {
      setState(() => selectedLanguage = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.battleService.currentUser;
    final rating = currentUser?.ratingForLanguage(selectedLanguage);
    final loc = context.loc;
    final languageKey = languageLabels[selectedLanguage] ?? "languageEnglish";
    final languageLabel =
        {
          "languageEnglish": loc.languageEnglish,
          "languageGerman": loc.languageGerman,
          "languageFrench": loc.languageFrench,
          "languageRomanian": loc.languageRomanian,
        }[languageKey] ??
        selectedLanguage;
    final hasNotifications = widget.battleService.friendRequests.isNotEmpty;

    final uiLocale = localeNotifier.value?.languageCode ?? 'en';
    final filteredLanguages = languageLabels.entries.where((e) {
      final localeMap = {
        'english': 'en',
        'german': 'de',
        'french': 'fr',
        'romanian': 'ro',
      };
      return localeMap[e.key] != uiLocale;
    }).toList();

    if (!filteredLanguages.any((e) => e.key == selectedLanguage)) {
      selectedLanguage = filteredLanguages.first.key;
    }

    // Flag emojis
    final flags = {
      'english': '🇬🇧',
      'german': '🇩🇪',
      'french': '🇫🇷',
      'romanian': '🇷🇴',
    };
    final currentFlag = flags[selectedLanguage] ?? '🇪🇸';

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.only(
          top: 10,
          left: 24,
          right: 24,
          bottom: 80,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F7F2), // bg-background
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.battleService.activeRoom != null)
              _buildActiveGameBanner(context),

            // Notifications Icon (moved from App Bar since user wants Settings as is)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Langbattle",
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF755700),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF1F1EC,
                          ), // surface-container-low
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF755700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsPage(
                              battleService: widget.battleService,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF1F1EC,
                          ), // surface-container-low
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF755700),
                            ),
                            if (hasNotifications)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // User Profile Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage(battleService: widget.battleService),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // surface-container-lowest
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D2F2C).withOpacity(0.1),
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
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF755700).withOpacity(0.1),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: UserAvatar(
                              name: currentUser?.name ?? '',
                              base64Image: currentUser?.avatarBase64,
                              size: 64,
                              borderRadius: 22,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6661), // tertiary
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
                            currentUser?.name ?? "Guest",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2D2F2C),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Language Selector Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1EC), // surface-container-low
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TARGET LANGUAGE",
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A5C58),
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      DropdownButton<String>(
                        value: selectedLanguage,
                        icon: const Icon(
                          Icons.expand_more,
                          color: Color(0xFF755700),
                        ),
                        elevation: 16,
                        style: const TextStyle(
                          color: Color(0xFF755700),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        underline: Container(height: 0),
                        onChanged: (String? value) {
                          if (value == null) return;
                          setState(() {
                            selectedLanguage = value;
                          });
                          SharedPreferences.getInstance().then(
                            (prefs) => prefs.setString(
                              Kconstants.battleLanguageKey,
                              value,
                            ),
                          );
                        },
                        items: filteredLanguages.map((e) {
                          final key = e.value;
                          final label =
                              {
                                "languageEnglish": loc.languageEnglish,
                                "languageGerman": loc.languageGerman,
                                "languageFrench": loc.languageFrench,
                                "languageRomanian": loc.languageRomanian,
                              }[key] ??
                              e.key;
                          return DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(
                              label,
                            ), // Show languages instead of "change"
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDC003),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF755700),
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            currentFlag,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageLabel,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: Color(0xFF2D2F2C),
                            ),
                          ),
                          Text(
                            (rating ?? 'N/A').toString() + " ELO",
                            style: const TextStyle(
                              color: Color(0xFF5A5C58),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bento Stats Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFDCDDD7,
                      ), // surface-container-highest
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CURRENT ELO",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A5C58),
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (rating ?? 1000).toString(),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w900,
                            fontSize: 36,
                            color: Color(0xFF2D2F2C),
                          ),
                        ),
                        const Text(
                          "Top 5% Globally",
                          style: TextStyle(
                            color: Color(0xFF0D6661),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFDCDDD7,
                      ), // surface-container-highest
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "WIN STREAK",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A5C58),
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "12",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w900,
                            fontSize: 36,
                            color: Color(0xFFAB2D00), // secondary
                          ),
                        ),
                        const Text(
                          "Matches won",
                          style: TextStyle(
                            color: Color(0xFF5A5C58),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Battle Now Hero Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: const Color(0xFF755700).withOpacity(0.05),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF755700).withOpacity(0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildModeSelector(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDC003),
                      foregroundColor: const Color(0xFF553E00),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: const Size(double.infinity, 64),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return _buildBattleScreen(
                              language: selectedLanguage,
                              mode: selectedMode,
                            );
                          },
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.sports_kabaddi, size: 28),
                        SizedBox(width: 12),
                        Text(
                          "BATTLE NOW",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${widget.battleService.onlineCount} Players Online Now",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A5C58),
                      letterSpacing: -0.5,
                    ),
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
