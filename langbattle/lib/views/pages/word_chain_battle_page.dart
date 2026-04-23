import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langbattle/extensions/context_extensions.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/widgets/user_avatar.dart';

class WordChainBattleScreen extends StatefulWidget {
  final BattleService battleService;
  final String language;
  final Map<String, dynamic>? restoredRoom;

  const WordChainBattleScreen({
    super.key,
    required this.battleService,
    required this.language,
    this.restoredRoom,
  });

  @override
  State<WordChainBattleScreen> createState() => _WordChainBattleScreenState();
}

class _WordChainBattleScreenState extends State<WordChainBattleScreen> {
  final TextEditingController _wordController = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _timer;
  Timer? _waitTimer;

  bool isWaitingForOpponent = true;
  bool opponentFinished = false;
  bool iFinished = false;
  bool gameOver = false;
  int remainingSeconds = 0;
  int waitSeconds = 0;
  Map<String, int> scores = {"me": 0, "opponent": 0};
  List<String> usedWords = [];
  String? currentWord;
  String? opponentName;
  String? opponentAvatar;
  String? myAvatar;
  String? myName;
  String? errorText;
  Map<String, dynamic>? ratingUpdate;

  @override
  void initState() {
    super.initState();
    myAvatar = widget.battleService.currentUser?.avatarBase64;
    myName = widget.battleService.currentUser?.name;

    final restored = widget.restoredRoom;
    if (restored != null) {
      _restoreRoom(restored);
    } else {
      widget.battleService.joinQueue(
        language: widget.language,
        mode: "word_chain",
      );
      _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && isWaitingForOpponent) {
          setState(() => waitSeconds++);
        }
      });
    }

    _sub = widget.battleService.stream.listen(_handleEvent);
  }

  void _restoreRoom(Map<String, dynamic> room) {
    scores["me"] = room["myScore"] ?? 0;
    scores["opponent"] = room["opponentScore"] ?? 0;
    opponentName = room["opponentName"] ?? "Opponent";
    opponentFinished = room["opponentFinished"] == true;
    currentWord = room["currentWord"]?.toString();
    usedWords = _toStringList(room["usedWords"]);
    isWaitingForOpponent = false;
    remainingSeconds = _computeRemainingSeconds(
      endsAt: room["endsAt"],
      durationSeconds: room["durationSeconds"],
    );

    if (remainingSeconds > 0 && !opponentFinished) {
      _startGameTimer();
    } else {
      iFinished = true;
      _maybeEndGame();
    }
  }

  void _handleEvent(Map<String, dynamic> data) {
    final type = data["type"];
    if (!mounted) return;

    if (type == "match_found") {
      final mode = data["mode"]?.toString() ?? "classic";
      if (mode != "word_chain" || !isWaitingForOpponent) return;

      final players = (data["players"] as List<dynamic>? ?? const []);
      final myUserId = widget.battleService.currentUser?.userId;
      final opponent = players.firstWhere(
        (p) => p["userId"]?.toString() != myUserId,
        orElse: () => players.isNotEmpty ? players.last : <String, dynamic>{},
      );

      _waitTimer?.cancel();
      setState(() {
        isWaitingForOpponent = false;
        widget.battleService.roomId = data["roomId"]?.toString();
        opponentName = opponent["name"]?.toString() ?? "Opponent";
        opponentAvatar = opponent["avatarBase64"]?.toString();
        currentWord = data["startWord"]?.toString();
        usedWords = _toStringList(data["usedWords"]);
        scores = {"me": 0, "opponent": 0};
        opponentFinished = false;
        iFinished = false;
        gameOver = false;
        errorText = null;
        remainingSeconds = _computeRemainingSeconds(
          endsAt: data["endsAt"],
          durationSeconds: data["durationSeconds"],
        );
      });
      _startGameTimer();
      return;
    }

    if (type == "player_event") {
      final payload = data["payload"] as Map<String, dynamic>? ?? const {};
      final action = payload["action"]?.toString();
      final myId = widget.battleService.currentUser?.userId;
      final playerId = payload["playerId"]?.toString();
      final isMe = myId != null && playerId == myId;

      if (action == "word_chain_move") {
        final valid = payload["valid"] == true;
        if (!valid) {
          if (isMe) {
            setState(() {
              errorText = payload["error"]?.toString() ?? "Invalid word.";
            });
          }
          return;
        }

        setState(() {
          currentWord = payload["currentWord"]?.toString() ?? currentWord;
          usedWords = _toStringList(payload["usedWords"]);
          scores[isMe ? "me" : "opponent"] =
              (scores[isMe ? "me" : "opponent"] ?? 0) + 1;
          errorText = null;
        });

        if (isMe) {
          _wordController.clear();
        }
        return;
      }

      if ((action == "finished" || action == "finish") &&
          playerId != null &&
          playerId != myId) {
        setState(() {
          opponentFinished = true;
        });
        _maybeEndGame();
      }

      return;
    }

    if (type == "rating_updated") {
      setState(() {
        ratingUpdate = data;
      });
      return;
    }

    if (type == "opponent_disconnected") {
      _timer?.cancel();
      setState(() {
        gameOver = true;
        opponentFinished = true;
      });
    }
  }

  List<String> _toStringList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) => item.toString()).toList();
  }

  int _computeRemainingSeconds({dynamic endsAt, dynamic durationSeconds}) {
    if (endsAt != null) {
      final parsed = DateTime.tryParse(endsAt.toString());
      if (parsed != null) {
        final seconds = parsed.difference(DateTime.now()).inSeconds;
        return seconds > 0 ? seconds : 0;
      }
    }

    final fallback = durationSeconds is int
        ? durationSeconds
        : int.tryParse(durationSeconds?.toString() ?? "");
    return fallback ?? 60;
  }

  void _startGameTimer() {
    _timer?.cancel();
    if (remainingSeconds <= 0) {
      _onTimeUp();
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remainingSeconds <= 1) {
        timer.cancel();
        _onTimeUp();
      } else {
        setState(() {
          remainingSeconds -= 1;
        });
      }
    });
  }

  void _onTimeUp() {
    if (iFinished) return;
    setState(() {
      iFinished = true;
    });
    _onLocalFinished();
  }

  void _onLocalFinished() {
    _timer?.cancel();
    widget.battleService.sendFinish(score: scores["me"] ?? 0);
    _maybeEndGame();
  }

  void _maybeEndGame() {
    if (iFinished && opponentFinished) {
      setState(() {
        gameOver = true;
      });
    }
  }

  void _submitWord() {
    if (gameOver || iFinished) return;

    final word = _wordController.text.trim();
    if (word.isEmpty) {
      setState(() {
        errorText = "Enter a word first.";
      });
      return;
    }

    widget.battleService.submitWordChainWord(word);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waitTimer?.cancel();
    _sub?.cancel();
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    if (isWaitingForOpponent) {
      final formattedTime =
          "${(waitSeconds ~/ 60).toString().padLeft(2, '0')}:${(waitSeconds % 60).toString().padLeft(2, '0')}";
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F2),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Langbattle",
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Color(0xFF755700),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF755700).withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6661).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          "WORD CHAIN",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: Color(0xFF0D6661),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 56,
                          color: Color(0xFF2D2F2C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Finding an opponent for ${widget.language.toUpperCase()}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF5A5C58),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2F2C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () {
                      widget.battleService.leaveQueue();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Cancel Search",
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (gameOver) {
      final myScore = scores["me"] ?? 0;
      final opponentScore = scores["opponent"] ?? 0;
      final isDraw = myScore == opponentScore;
      final isVictory = myScore > opponentScore;
      final resultText = isDraw ? "DRAW" : (isVictory ? "VICTORY" : "DEFEAT");

      return Scaffold(
        backgroundColor: const Color(0xFFFBFBF9),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF5A5C58)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      Text(
                        resultText,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 42,
                          color: Color(0xFF2D2F2C),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildResultPlayer(
                            name: myName ?? "Me",
                            image: myAvatar,
                            score: myScore,
                            highlight: isVictory || isDraw,
                            ratingDelta: ratingUpdate?["delta"] as int?,
                          ),
                          const Text(
                            "VS",
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Color(0x665A5C58),
                            ),
                          ),
                          _buildResultPlayer(
                            name: opponentName ?? "Opponent",
                            image: opponentAvatar,
                            score: opponentScore,
                            highlight: !isVictory || isDraw,
                          ),
                        ],
                      ),
                      if (ratingUpdate != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          "${ratingUpdate!["oldRating"]} -> ${ratingUpdate!["newRating"]}",
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF2D2F2C),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDC003),
                      foregroundColor: const Color(0xFF553E00),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      loc.returnToHome,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (iFinished && !opponentFinished) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loc.youFinishedWaitingOpponent,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  "Current score: ${scores["me"] ?? 0} - ${scores["opponent"] ?? 0}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final nextLetter = currentWord == null || currentWord!.isEmpty
        ? "?"
        : currentWord![currentWord!.length - 1].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF755700)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "WORD CHAIN",
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Color(0xFF755700),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      "${remainingSeconds}s",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Color(0xFF2D2F2C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildScoreBoard(),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    const Text(
                      "CURRENT WORD",
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.6,
                        color: Color(0xFF5A5C58),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentWord ?? "...",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                        color: Color(0xFF0D6661),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your next word must start with $nextLetter",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF5A5C58),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _wordController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitWord(),
                        decoration: const InputDecoration(
                          hintText: "Type a word",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDC003),
                        foregroundColor: const Color(0xFF553E00),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _submitWord,
                      child: const Text(
                        "Play",
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4DE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      fontFamily: 'Be Vietnam Pro',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFAB2D00),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFE8),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "USED WORDS",
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.6,
                          color: Color(0xFF5A5C58),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: usedWords.map((word) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  word,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D2F2C),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultPlayer({
    required String name,
    required String? image,
    required int score,
    required bool highlight,
    int? ratingDelta,
  }) {
    return Expanded(
      child: Opacity(
        opacity: highlight ? 1 : 0.6,
        child: Column(
          children: [
            UserAvatar(
              name: name,
              base64Image: image,
              size: 72,
              borderRadius: 20,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF2D2F2C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$score",
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: Color(0xFF2D2F2C),
              ),
            ),
            if (ratingDelta != null)
              Text(
                "${ratingDelta >= 0 ? '+' : ''}$ratingDelta",
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  color: ratingDelta >= 0
                      ? const Color(0xFF0D6661)
                      : const Color(0xFFAB2D00),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Row(
      children: [
        Expanded(
          child: _buildScoreCard(
            name: myName ?? "Me",
            image: myAvatar,
            score: scores["me"] ?? 0,
            accent: const Color(0xFFFDC003),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildScoreCard(
            name: opponentName ?? "Opponent",
            image: opponentAvatar,
            score: scores["opponent"] ?? 0,
            accent: const Color(0xFFE8E9E3),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard({
    required String name,
    required String? image,
    required int score,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: name,
            base64Image: image,
            size: 44,
            borderRadius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF2D2F2C),
                  ),
                ),
                Text(
                  "$score",
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: accent == const Color(0xFFFDC003)
                        ? const Color(0xFF553E00)
                        : const Color(0xFF2D2F2C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
