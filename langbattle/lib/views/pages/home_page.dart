import "package:flutter/material.dart";
import 'package:langbattle/views/pages/settings_page.dart';
import 'package:langbattle/data/notifiers.dart';
import 'dart:async';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/battle_page.dart';
import 'package:langbattle/views/pages/profile/profile_page.dart';
import 'package:langbattle/views/pages/notifications_page.dart';
import 'package:langbattle/views/pages/word_chain_battle_page.dart';
import 'package:langbattle/widgets/language_flag.dart';
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
  bool _openingChallengeMatch = false;

  final List<Map<String, String>> modes = [
    {"key": "classic", "title": "Classic"},
    {"key": "word_chain", "title": "Word Chain"},
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
          type == "online_count" ||
          type == "rating_updated" ||
          type == "challenge_received" ||
          type == "challenge_updated" ||
          type == "challenge_declined" ||
          type == "challenge_expired") {
        setState(() {});
      }
      if (type == "challenge_received") {
        final fromName = event["fromName"]?.toString() ?? "A player";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$fromName challenged you")));
      }
      if (type == "match_found" && event["challenge"] == true) {
        _openChallengeMatch(event);
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
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
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
                    ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
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

  IconData _iconForMode(String? key) {
    switch (key) {
      case "word_chain":
        return Icons.link;
      case "classic":
      default:
        return Icons.track_changes;
    }
  }

  Widget _buildModeSelector() {
    return Row(
      children: modes.map((mode) {
        final modeKey = mode["key"]!;
        final isSelected = selectedMode == modeKey;
        final selectedColor = isSelected
            ? const Color(0xFFFDC003)
            : const Color(0xFFDCDDD7);
        final foregroundColor = isSelected
            ? const Color(0xFF553E00)
            : const Color(0xFF5A5C58);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: mode == modes.first ? 0 : 6,
              right: mode == modes.last ? 0 : 6,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedMode = modeKey;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 84,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF4C7) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFDC003)
                        : const Color(0xFFE1E1DC),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _iconForMode(modeKey),
                        color: foregroundColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        mode["title"]!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isSelected
                              ? const Color(0xFF2D2F2C)
                              : const Color(0xFF5A5C58),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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

  void _openChallengeMatch(Map<String, dynamic> event) {
    if (_openingChallengeMatch) return;
    _openingChallengeMatch = true;

    final players = event["players"] as List<dynamic>? ?? const [];
    final myUserId = widget.battleService.currentUser?.userId;
    final opponent = players.firstWhere(
      (p) => p["userId"]?.toString() != myUserId,
      orElse: () => players.isNotEmpty ? players.last : <String, dynamic>{},
    );
    final mode = event["mode"]?.toString() ?? "classic";
    final restoredRoom = <String, dynamic>{
      "roomId": event["roomId"],
      "mode": mode,
      "language": event["language"] ?? "english",
      "questions": event["questions"] ?? const [],
      "myScore": 0,
      "opponentScore": 0,
      "opponentName": opponent["name"]?.toString() ?? "Opponent",
      "opponentAvatar": opponent["avatarBase64"]?.toString(),
      "opponentFinished": false,
      "myCurrentIndex": 0,
      "currentWord": event["startWord"],
      "startWord": event["startWord"],
      "usedWords": event["usedWords"] ?? const [],
      "durationSeconds": event["durationSeconds"],
      "endsAt": event["endsAt"],
    };

    widget.battleService.roomId = event["roomId"]?.toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _buildBattleScreen(
          language: event["language"]?.toString() ?? "english",
          mode: mode,
          restoredRoom: restoredRoom,
        ),
      ),
    ).whenComplete(() {
      _openingChallengeMatch = false;
    });
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
    final hasNotifications =
        widget.battleService.friendRequests.isNotEmpty ||
        widget.battleService.challenges.isNotEmpty;

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

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(
            top: 18,
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
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(
                                  0xFF755700,
                                ).withValues(alpha: 0.1),
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
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _WinStreakBadge(streak: currentUser?.winStreak ?? 0),
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
                        LanguageFlag(
                          language: selectedLanguage,
                          width: 76,
                          height: 54,
                          borderRadius: 14,
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
                              "${rating ?? 'N/A'} ELO",
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
              const SizedBox(height: 24),

              // Battle Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1EC),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "BATTLE",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A5C58),
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0D6661),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${widget.battleService.onlineCount} online",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5A5C58),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                    _BattleButton(
                      label: "BATTLE NOW",
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinStreakBadge extends StatelessWidget {
  final int streak;

  const _WinStreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4C7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CustomPaint(painter: _FireSvgPainter()),
          ),
          const SizedBox(width: 6),
          Text(
            "$streak",
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Color(0xFF553E00),
            ),
          ),
        ],
      ),
    );
  }
}

class _FireSvgPainter extends CustomPainter {
  const _FireSvgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.1294117647, 0);
    canvas.scale(size.width / 255, size.height / 255);

    final outerPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFFFF4C0D), Color(0xFFFC9502)],
      ).createShader(const Rect.fromLTWH(0, 0, 188, 255));

    final outerPath = Path()
      ..moveTo(187.899, 164.809)
      ..cubicTo(185.803, 214.868, 144.574, 254.812, 94.000, 254.812)
      ..cubicTo(42.085, 254.812, 0.000, 211.312, 0.000, 160.812)
      ..cubicTo(0.000, 154.062, -0.121, 140.572, 10.000, 117.812)
      ..cubicTo(16.057, 104.191, 19.856, 95.634, 22.000, 87.812)
      ..cubicTo(23.178, 83.513, 25.469, 76.683, 32.000, 87.812)
      ..cubicTo(35.851, 94.374, 36.000, 103.812, 36.000, 103.812)
      ..cubicTo(36.000, 103.812, 50.328, 92.817, 60.000, 71.812)
      ..cubicTo(74.179, 41.019, 62.866, 22.612, 59.000, 9.812)
      ..cubicTo(57.662, 5.384, 56.822, -2.574, 66.000, 0.812)
      ..cubicTo(75.352, 4.263, 100.076, 21.570, 113.000, 39.812)
      ..cubicTo(131.445, 65.847, 138.000, 90.812, 138.000, 90.812)
      ..cubicTo(138.000, 90.812, 143.906, 83.482, 146.000, 75.812)
      ..cubicTo(148.365, 67.151, 148.400, 58.573, 155.999, 67.813)
      ..cubicTo(163.226, 76.600, 173.959, 93.113, 180.000, 108.812)
      ..cubicTo(190.969, 137.321, 187.899, 164.809, 187.899, 164.809)
      ..close();
    canvas.drawPath(outerPath, outerPaint);

    final middlePath = Path()
      ..moveTo(94.000, 254.812)
      ..cubicTo(58.101, 254.812, 29.000, 225.711, 29.000, 189.812)
      ..cubicTo(29.000, 168.151, 37.729, 155.000, 55.896, 137.166)
      ..cubicTo(67.528, 125.747, 78.415, 111.722, 83.042, 102.172)
      ..cubicTo(83.953, 100.292, 86.026, 90.495, 94.019, 101.966)
      ..cubicTo(98.212, 107.982, 104.785, 118.681, 109.000, 127.812)
      ..cubicTo(116.266, 143.555, 118.000, 158.812, 118.000, 158.812)
      ..cubicTo(118.000, 158.812, 125.121, 154.616, 130.000, 143.812)
      ..cubicTo(131.573, 140.330, 134.753, 127.148, 143.643, 140.328)
      ..cubicTo(150.166, 150.000, 159.127, 167.390, 159.000, 189.812)
      ..cubicTo(159.000, 225.711, 129.898, 254.812, 94.000, 254.812)
      ..close();
    canvas.drawPath(middlePath, Paint()..color = const Color(0xFFFC9502));

    final innerPath = Path()
      ..moveTo(95.000, 183.812)
      ..cubicTo(104.250, 183.812, 104.250, 200.941, 116.000, 223.812)
      ..cubicTo(123.824, 239.041, 112.121, 254.812, 95.000, 254.812)
      ..cubicTo(77.879, 254.812, 69.000, 240.933, 69.000, 223.812)
      ..cubicTo(69.000, 206.692, 85.750, 183.812, 95.000, 183.812)
      ..close();
    canvas.drawPath(innerPath, Paint()..color = const Color(0xFFFCE202));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BattleButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _BattleButton({required this.label, required this.onPressed});

  @override
  State<_BattleButton> createState() => _BattleButtonState();
}

class _BattleButtonState extends State<_BattleButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    const buttonHeight = 72.0;
    const edgeHeight = 6.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight + edgeHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: buttonHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF755700),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            top: _isPressed ? edgeHeight - 2 : 0,
            height: buttonHeight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: widget.onPressed,
                onTapDown: (_) => _setPressed(true),
                onTapCancel: () => _setPressed(false),
                onTapUp: (_) => _setPressed(false),
                child: Ink(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDC003),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 0,
                        color: Color(0xFF553E00),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
