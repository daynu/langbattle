import re

with open(r"c:\Users\danu1\OneDrive\Documents\LangBattle\langbattle\lib\views\pages\battle_page.dart", "r", encoding="utf8") as f:
    content = f.read()

# 1. Add wait timer variables to _BattleScreenState
state_vars_original = """  int remainingSeconds = 0;
  Timer? _timer;"""
state_vars_new = """  int remainingSeconds = 0;
  Timer? _timer;
  int waitSeconds = 0;
  Timer? _waitTimer;"""
content = content.replace(state_vars_original, state_vars_new)

# 2. Start wait timer in initState
init_state_original = """    } else {
      widget.battleService.joinQueue(language: widget.language);
    }"""
init_state_new = """    } else {
      widget.battleService.joinQueue(language: widget.language);
      _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && isWaitingForOpponent) {
          setState(() => waitSeconds++);
        }
      });
    }"""
content = content.replace(init_state_original, init_state_new)

# 3. Stop wait timer when match found
match_found_original = """        setState(() {
          isWaitingForOpponent = false;"""
match_found_new = """        _waitTimer?.cancel();
        setState(() {
          isWaitingForOpponent = false;"""
content = content.replace(match_found_original, match_found_new)

# 4. Cancel wait timer in dispose
dispose_original = """  void dispose() {
    _timer?.cancel();
    super.dispose();"""
dispose_new = """  void dispose() {
    _timer?.cancel();
    _waitTimer?.cancel();
    super.dispose();"""
content = content.replace(dispose_original, dispose_new)

# 5. Replace waiting screen UI
waiting_ui_original = """    if (isWaitingForOpponent) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.battleService.leaveQueue();
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Text(
            loc.waitingForOpponent,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }"""

waiting_ui_new = """    if (isWaitingForOpponent) {
      final String formattedTime =
          "${(waitSeconds ~/ 60).toString().padLeft(2, '0')}:${(waitSeconds % 60).toString().padLeft(2, '0')}";

      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F2),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    const Text(
                      "Langbattle",
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.5,
                        color: Color(0xFF755700),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Main Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF755700).withOpacity(0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF755700).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.sports_kabaddi, size: 16, color: Color(0xFF755700)),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${widget.language.toUpperCase()} BATTLE",
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 0.6,
                                        color: Color(0xFF755700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 60,
                                  letterSpacing: -3.0,
                                  color: Color(0xFF2D2F2C),
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFAB2D00).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  "SEARCHING FOR A MATCH...",
                                  style: TextStyle(
                                    fontFamily: 'Be Vietnam Pro',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                    color: Color(0xFFAB2D00),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // User Info Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFFE8E9E3), width: 2),
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
                                  const SizedBox(width: 6),
                                  const Text(
                                    "ONLINE",
                                    style: TextStyle(
                                      fontFamily: 'Be Vietnam Pro',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9,
                                      letterSpacing: 0.45,
                                      color: Color(0xFF5A5C58),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "12,482",
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF2D2F2C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      widget.battleService.currentUser?.name ?? "Me",
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF2D2F2C),
                                      ),
                                    ),
                                    const Text(
                                      "Finding...",
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Color(0xFF767773),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDC003),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFDC003).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.person, color: Color(0xFF553E00), size: 24),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2F2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        minimumSize: const Size(double.infinity, 64),
                      ),
                      onPressed: () {
                        widget.battleService.leaveQueue();
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.close, color: Color(0xFFF87171), size: 24),
                          SizedBox(width: 12),
                          Text(
                            "CANCEL SEARCH",
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        widget.battleService.leaveQueue();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "RETURN TO LOBBY",
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 2.0,
                          color: Color(0xFF5A5C58),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }"""

content = content.replace(waiting_ui_original, waiting_ui_new)

with open(r"c:\Users\danu1\OneDrive\Documents\LangBattle\langbattle\lib\views\pages\battle_page.dart", "w", encoding="utf8") as f:
    f.write(content)
