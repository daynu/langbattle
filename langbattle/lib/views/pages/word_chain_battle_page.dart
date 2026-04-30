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
    opponentAvatar = room["opponentAvatar"]?.toString();
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
      final resultColor = isDraw
          ? const Color(0xFFE2E3DD)
          : (isVictory ? const Color(0xFFFFC107) : const Color(0xFFF95630));
      final onResultColor = isDraw
          ? const Color(0xFF5A5C58)
          : (isVictory ? const Color(0xFF553E00) : const Color(0xFF520C00));
      final resultRatingDelta = ratingUpdate?["delta"] as int?;
      final ratingDeltaColor = resultRatingDelta == null
          ? const Color(0x995A5C58)
          : resultRatingDelta > 0
          ? const Color(0xFF0D6661)
          : resultRatingDelta < 0
          ? const Color(0xFFB02500)
          : const Color(0x995A5C58);

      return Scaffold(
        backgroundColor: const Color(0xFFFBFBF9),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF5A5C58)),
                      onPressed: () => Navigator.pop(context),
                      hoverColor: const Color(0xFFDCDDD7),
                    ),
                    const Text(
                      "Battle Results",
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0,
                        color: Color(0xFF2D2F2C),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  child: Column(
                    children: [
                      Transform.rotate(
                        angle: -0.0174533,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: resultColor,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: resultColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Text(
                            resultText,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 48,
                              color: onResultColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: const Color(0xFFE8E9E3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildPlayerResultColumn(
                                  name: myName ?? "Me",
                                  base64Image: myAvatar,
                                  score: myScore,
                                  isWinner: isVictory || isDraw,
                                ),
                                const Text(
                                  "VS",
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 20,
                                    color: Color(0x335A5C58),
                                  ),
                                ),
                                _buildPlayerResultColumn(
                                  name: opponentName ?? "Opponent",
                                  base64Image: opponentAvatar,
                                  score: opponentScore,
                                  isWinner: !isVictory || isDraw,
                                ),
                              ],
                            ),
                            if (ratingUpdate != null) ...[
                              const SizedBox(height: 32),
                              const Divider(color: Color(0xFFE8E9E3)),
                              const SizedBox(height: 32),
                              const Text(
                                "RATING PROGRESSION",
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 2.0,
                                  color: Color(0x995A5C58),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${ratingUpdate!["oldRating"]}",
                                    style: const TextStyle(
                                      fontFamily: 'Be Vietnam Pro',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Color(0xFF5A5C58),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (resultRatingDelta != null) ...[
                                        Text(
                                          "${resultRatingDelta >= 0 ? '+' : ''}$resultRatingDelta",
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            color: ratingDeltaColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Icon(
                                        Icons.arrow_forward,
                                        color: ratingDeltaColor,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    "${ratingUpdate!["newRating"]}",
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 30,
                                      color: Color(0xFF2D2F2C),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8E9E3),
                          foregroundColor: const Color(0xFF2D2F2C),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          minimumSize: const Size(double.infinity, 64),
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
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildPlayerResultColumn({
    required String name,
    required String? base64Image,
    required int score,
    required bool isWinner,
  }) {
    final child = Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x33FFC107), width: 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: UserAvatar(
                  name: name,
                  base64Image: base64Image,
                  size: 80,
                  borderRadius: 24,
                ),
              ),
            ),
            if (isWinner)
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isWinner ? const Color(0xFF2D2F2C) : const Color(0xFF5A5C58),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "$score",
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: isWinner ? const Color(0xFF2D2F2C) : const Color(0xFF5A5C58),
          ),
        ),
      ],
    );

    return isWinner ? child : Opacity(opacity: 0.6, child: child);
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
