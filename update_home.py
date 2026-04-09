import re

with open(r"c:\Users\danu1\OneDrive\Documents\LangBattle\langbattle\lib\views\pages\home_page.dart", "r", encoding="utf8") as f:
    content = f.read()

prefix = content.split("  @override\n  Widget build(BuildContext context) {")[0]

build_method = """  @override
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
        padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 80),
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
                      color: const Color(0xFFF1F1EC), // surface-container-low
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
            const SizedBox(height: 24),

            // User Profile Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(battleService: widget.battleService),
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
                    )
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
                            border: Border.all(color: const Color(0xFF755700).withOpacity(0.1), width: 2),
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
                          Text(
                            "@${(currentUser?.name ?? "Guest").replaceAll(' ', '_')}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF5A5C58), // on-surface-variant
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDC003).withOpacity(0.2), // primary-container
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  "LEVEL ${(rating ?? 1000) ~/ 100}",
                                  style: const TextStyle(
                                    color: Color(0xFF755700),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0D6661),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    "ACTIVE NOW",
                                    style: TextStyle(
                                      color: Color(0xFF0D6661),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_outlined, color: Color(0xFF767773)),
                    )
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
                        icon: const Icon(Icons.expand_more, color: Color(0xFF755700)),
                        elevation: 16,
                        style: const TextStyle(color: Color(0xFF755700), fontWeight: FontWeight.bold, fontSize: 14),
                        underline: Container(
                          height: 0,
                        ),
                        onChanged: (String? value) {
                          if (value == null) return;
                          setState(() {
                            selectedLanguage = value;
                          });
                          SharedPreferences.getInstance().then(
                            (prefs) => prefs.setString(Kconstants.battleLanguageKey, value),
                          );
                        },
                        items: filteredLanguages.map((e) {
                          final key = e.value;
                          final label = {
                            "languageEnglish": loc.languageEnglish,
                            "languageGerman": loc.languageGerman,
                            "languageFrench": loc.languageFrench,
                            "languageRomanian": loc.languageRomanian,
                          }[key] ?? e.key;
                          return DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(label), // Show languages instead of "change"
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
                          )
                        ],
                      ),
                    ],
                  )
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
                      color: const Color(0xFFDCDDD7), // surface-container-highest
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
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCDDD7), // surface-container-highest
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
                        )
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
                border: Border.all(color: const Color(0xFF755700).withOpacity(0.05), width: 2),
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
                  const Text(
                    "Ready for Battle?",
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      color: Color(0xFF2D2F2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Challenge a random opponent and climb the leaderboard.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF5A5C58),
                      fontSize: 14,
                    ),
                  ),
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
                      minimumSize: const Size(Double.infinity, 64),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return BattleScreen(
                          battleService: widget.battleService,
                          language: selectedLanguage,
                        );
                      }));
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
                  const Text(
                    "4,281 Players Online Now",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A5C58),
                      letterSpacing: -0.5,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Secondary Actions
            GestureDetector(
              onTap: () {
                // Placeholder for Practice Arena
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1EC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA7F3EC), // tertiary-container
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.school, color: Color(0xFF005E59)), // on-tertiary-container
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Practice Arena", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D2F2C), fontSize: 16)),
                          Text("Solo training against AI bots", style: TextStyle(color: Color(0xFF5A5C58), fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF767773)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                     builder: (context) => FriendsPage(battleService: widget.battleService),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1EC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC4B4), // secondary-container
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.group, color: Color(0xFF882200)), // on-secondary-container
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Friends League", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D2F2C), fontSize: 16)),
                          Text("Compete with your social circle", style: TextStyle(color: Color(0xFF5A5C58), fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF767773)),
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
"""

final_content = prefix + build_method

with open(r"c:\Users\danu1\OneDrive\Documents\LangBattle\langbattle\lib\views\pages\home_page.dart", "w", encoding="utf8") as f:
    f.write(final_content)
