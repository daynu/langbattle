import "package:flutter/material.dart";
import 'package:langbattle/data/notifiers.dart';
import 'dart:async';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/battle_page.dart';
import 'package:langbattle/views/pages/profile/profile_page.dart';
import 'package:langbattle/views/pages/notifications_page.dart';
import 'package:langbattle/widgets/user_avatar.dart';
import 'package:lottie/lottie.dart';
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
          type == "friend_added") {
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



Future<void> _loadSavedLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(Kconstants.battleLanguageKey);
  final uiLocale = localeNotifier.value?.languageCode ?? 'en';
  final localeMap = {'english': 'en', 'german': 'de', 'french': 'fr', 'romanian': 'ro'};
  if (saved != null && languageLabels.containsKey(saved) && localeMap[saved] != uiLocale) {
    setState(() => selectedLanguage = saved);
  }
}

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.battleService.currentUser;
    final rating = currentUser?.ratingForLanguage(selectedLanguage);
    final loc = context.loc;
    final languageKey = languageLabels[selectedLanguage] ?? "languageEnglish";
    final languageLabel = {
      "languageEnglish": loc.languageEnglish,
      "languageGerman": loc.languageGerman,
      "languageFrench": loc.languageFrench,
      "languageRomanian": loc.languageRomanian,
    }[languageKey] ?? selectedLanguage;
    final hasNotifications =
        widget.battleService.friendRequests.isNotEmpty;

  
  final uiLocale = localeNotifier.value?.languageCode ?? 'en';
final filteredLanguages = languageLabels.entries.where((e) {
  // e.key is the language key like "english", "german", etc.
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


    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfilePage(battleService: widget.battleService),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          UserAvatar(
                          name: currentUser?.name ?? '',
                          base64Image: currentUser?.avatarBase64,
                          size: 40,
                          borderRadius: 8,
                        ),
                          const SizedBox(width: 8),
                          Text(
                            currentUser?.name ?? "Profile",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            size: 28,
                          ),
                          if (hasNotifications)
                            Positioned(
                              right: 0,
                              top: -1,
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
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedLanguage,
                        decoration: InputDecoration(
                          labelText: loc.selectLanguage,
                          border: const OutlineInputBorder(),
                        ),
                        items: filteredLanguages
                            .map(
                              (e) {
                                final key = e.value;
                                final label = {
                                  "languageEnglish": loc.languageEnglish,
                                  "languageGerman": loc.languageGerman,
                                  "languageFrench": loc.languageFrench,
                                  "languageRomanian": loc.languageRomanian,
                                }[key] ?? e.key;
                                return DropdownMenuItem<String>(
                                  value: e.key,
                                  child: Text(label),
                                );
                              },
                            )
                            .toList(),
                        onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedLanguage = value;
                            });
                            // ← add this
                            SharedPreferences.getInstance().then(
                              (prefs) => prefs.setString(Kconstants.battleLanguageKey, value),
                            );
                          },
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (currentUser != null)
                      Text(
                        loc.ratingForLanguage(
                          languageLabel,
                          (rating ?? 'N/A').toString(),
                        ),
                        style: const TextStyle(fontSize: 16),
                      )
                    else
                      Text(
                        loc.loginToSeeRating,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            Lottie.asset(
              'assets/lotties/#0101FTUE_04.json',
              width: 600,
              height: 400,
            ),

            const SizedBox(height: 20),

            Center(
              child: SizedBox(
                width: 220,
                child: ElevatedButton(onPressed: () {
              

              Navigator.push(context, 
              
              MaterialPageRoute(builder: (context) {
                return BattleScreen(
                battleService: widget.battleService,
                language: selectedLanguage,
                );
              }

              ));
              
            }, child: Text(loc.battleNow)),
              ),
            ),

          ],
        ),
        
      ),
    );
  }
}
