import 'package:flutter/material.dart';
import 'package:langbattle/objects/question.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/extensions/context_extensions.dart';
import 'dart:async';
import 'package:langbattle/widgets/gap_fill_widget.dart';
import 'review_answers_screen.dart';
import 'package:langbattle/widgets/user_avatar.dart';

class BattleScreen extends StatefulWidget {
  final BattleService battleService;
  final String language;
  final Map<String, dynamic>? restoredRoom;
  final String mode;

  const BattleScreen({
    super.key,
    required this.battleService,
    required this.language,
    required this.mode,
    this.restoredRoom,
  });

  @override
  _BattleScreenState createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  int currentIndex = 0;
  bool isWaitingForOpponent = true;
  Map<String, int> scores = {"me": 0, "opponent": 0};
  String? opponentName;
  List<Question> questions = [];
  bool opponentFinished = false;
  bool iFinished = false;
  bool gameOver = false;
  int remainingSeconds = 0;
  Timer? _timer;
  int waitSeconds = 0;
  Timer? _waitTimer;
  Map<String, dynamic>? ratingUpdate;
  Map<String, String> myAnswers = {};
  String? opponentAvatar;
  String? myAvatar;
  String? myName;

  @override
  void initState() {
    super.initState();

    myAvatar = widget.battleService.currentUser?.avatarBase64;
    myName = widget.battleService.currentUser?.name;

    final restored = widget.restoredRoom;
    if (restored != null) {
      questions = (restored["questions"] as List)
          .map((q) => Question.fromJson(Map<String, dynamic>.from(q)))
          .toList();
      scores["me"] = restored["myScore"] ?? 0;
      scores["opponent"] = restored["opponentScore"] ?? 0;
      opponentName = restored["opponentName"] ?? "Opponent";
      currentIndex = restored["myCurrentIndex"] ?? 0;
      opponentFinished = restored["opponentFinished"] ?? false;
      isWaitingForOpponent = false;
      _startTimerForCurrentQuestion();
    } else {
      widget.battleService.joinQueue(
        language: widget.language,
        mode: widget.mode,
      );
      _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && isWaitingForOpponent) {
          setState(() => waitSeconds++);
        }
      });
    }

    widget.battleService.stream.listen((data) {
      if (data["type"] == "player_event") {
        final payload = data["payload"] as Map<String, dynamic>?;
        if (payload == null) return;
        final String? action = payload["action"]?.toString();
        final String? playerId = payload["playerId"]?.toString();
        final String? myId = widget.battleService.currentUser?.userId;

        if (action == "answer") {
          final bool correct = payload["correct"] == true;
          final bool isMe = playerId == myId;
          if (correct) {
            setState(() {
              scores[isMe ? "me" : "opponent"] =
                  (scores[isMe ? "me" : "opponent"] ?? 0) + 1;
            });
          }
        }

        if ((action == "finished" || action == "finish") &&
            playerId != null &&
            playerId != myId) {
          setState(() {
            opponentFinished = true;
          });
          _maybeEndGame();
        }
      }

      if (data["type"] == "rating_updated") {
        setState(() {
          ratingUpdate = data;
        });
      }

      if (data["type"] == "match_found") {
        if (isWaitingForOpponent == false) return;
        print("Match found: ${data["roomId"]}");
        final players = data["players"] as List<dynamic>;
        final myUserId = widget.battleService.currentUser?.userId;
        final opponent = players.firstWhere(
          (p) => p["userId"]?.toString() != myUserId,
          orElse: () => players.last,
        );
        questions = (data["questions"] as List)
            .map((q) => Question.fromJson(q))
            .toList();

        _waitTimer?.cancel();
        setState(() {
          isWaitingForOpponent = false;
          widget.battleService.roomId = data["roomId"];
          opponentName = opponent["name"];
          currentIndex = 0;
          iFinished = false;
          opponentFinished = false;
          gameOver = false;
          opponentAvatar = opponent["avatarBase64"]?.toString();
        });
        _startTimerForCurrentQuestion();
      }

      if (data["type"] == "opponent_disconnected") {
        _timer?.cancel();
        setState(() {
          gameOver = true;
          opponentFinished = true;
        });
      }
    });
  }

  void _startTimerForCurrentQuestion() {
    _timer?.cancel();
    if (currentIndex >= questions.length) return;
    final int limit = questions[currentIndex].timeLimit;
    setState(() {
      remainingSeconds = limit;
    });
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
    if (currentIndex >= questions.length) return;
    setState(() {
      currentIndex += 1;
      if (currentIndex >= questions.length) {
        iFinished = true;
      }
    });
    if (iFinished) {
      _onLocalFinished();
    } else {
      _startTimerForCurrentQuestion();
    }
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

  @override
  void dispose() {
    _timer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }

  void answerQuestion(String answer) {
    if (currentIndex >= questions.length || gameOver) return;

    final question = questions[currentIndex];

    widget.battleService.sendAnswer(question.id, answer);
    myAnswers[question.id] = answer;

    _timer?.cancel();
    setState(() {
      currentIndex += 1;
      if (currentIndex >= questions.length) {
        iFinished = true;
      }
    });

    if (iFinished) {
      _onLocalFinished();
    } else {
      _startTimerForCurrentQuestion();
    }
  }

  Widget _buildWaitingScoreTile({
    required String name,
    required String? base64Image,
    required int score,
    required Color accentColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: UserAvatar(
            name: name,
            base64Image: base64Image,
            size: 62,
            borderRadius: 16,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0,
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
            letterSpacing: 0,
            color: Color(0xFF2D2F2C),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    if (isWaitingForOpponent) {
      final String formattedTime =
          "${(waitSeconds ~/ 60).toString().padLeft(2, '0')}:${(waitSeconds % 60).toString().padLeft(2, '0')}";

      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F2),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 40.0,
                            horizontal: 24.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF755700,
                                ).withOpacity(0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
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
                                  color: const Color(
                                    0xFF755700,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.sports_kabaddi,
                                      size: 16,
                                      color: Color(0xFF755700),
                                    ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFAB2D00,
                                  ).withOpacity(0.1),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFE8E9E3),
                                  width: 2,
                                ),
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
                                  Text(
                                    "${widget.battleService.onlineCount}",
                                    style: const TextStyle(
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
                                      widget.battleService.currentUser?.name ??
                                          "Me",
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
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFDC003,
                                        ).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF553E00),
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
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
                        setState(() {
                          isWaitingForOpponent = false;
                        });
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
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (gameOver) {
      final bool isVictory = (scores["me"] ?? 0) > (scores["opponent"] ?? 0);
      final bool isDraw = (scores["me"] ?? 0) == (scores["opponent"] ?? 0);
      final String resultText = isDraw
          ? "DRAW"
          : (isVictory ? "VICTORY" : "DEFEAT");
      final Color resultColor = isDraw
          ? const Color(0xFFE2E3DD)
          : (isVictory ? const Color(0xFFFFC107) : const Color(0xFFF95630));
      final Color onResultColor = isDraw
          ? const Color(0xFF5A5C58)
          : (isVictory ? const Color(0xFF553E00) : const Color(0xFF520C00));
      final int? resultRatingDelta = ratingUpdate?["delta"] as int?;
      final Color ratingDeltaColor = resultRatingDelta == null
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
              // Header
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
                        letterSpacing: -0.5,
                        color: Color(0xFF2D2F2C),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for centering title
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
                      // Victory / Defeat Badge
                      Transform.rotate(
                        angle: -0.0174533, // -1 degree
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
                                color: resultColor.withOpacity(0.2),
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

                      // Score Card
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
                            // VS Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Me
                                _buildPlayerResultColumn(
                                  name: myName ?? "Me",
                                  base64Image: myAvatar,
                                  score: scores["me"] ?? 0,
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

                                // Opponent
                                _buildPlayerResultColumn(
                                  name: opponentName ?? "Opponent",
                                  base64Image: opponentAvatar,
                                  score: scores["opponent"] ?? 0,
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

                      // Action Buttons
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: const Color(0xFF553E00),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          minimumSize: const Size(double.infinity, 64),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewAnswersScreen(
                                questions: questions,
                                myAnswers: myAnswers,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "REVIEW ANSWERS",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        onPressed: () {
                          Navigator.pop(context);
                        },
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
      final myScore = scores["me"] ?? 0;
      final opponentScore = scores["opponent"] ?? 0;

      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F2),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 24,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.pop(context),
                    child: Ink(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF5A5C58),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 88, 24, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: const Color(0xFFF1F1EC),
                              width: 6,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F755700),
                                blurRadius: 32,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: CircularProgressIndicator(
                                strokeWidth: 5,
                                color: Color(0xFFFDC003),
                                backgroundColor: Color(0xFFE8E9E3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        const Text(
                          "Battle submitted",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 42,
                            height: 1.1,
                            letterSpacing: 0,
                            color: Color(0xFF2D2F2C),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.youFinishedWaitingOpponent,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            letterSpacing: 0,
                            color: Color(0xFF5A5C58),
                          ),
                        ),
                        const SizedBox(height: 34),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(
                                0xFFADADA9,
                              ).withValues(alpha: 0.16),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildWaitingScoreTile(
                                      name:
                                          myName ??
                                          widget
                                              .battleService
                                              .currentUser
                                              ?.name ??
                                          "Me",
                                      base64Image: myAvatar,
                                      score: myScore,
                                      accentColor: const Color(0xFFFDC003),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      "VS",
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 0,
                                        color: Color(0xFFADADA9),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildWaitingScoreTile(
                                      name: opponentName ?? "Opponent",
                                      base64Image: opponentAvatar,
                                      score: opponentScore,
                                      accentColor: const Color(0xFFE8E9E3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F1EC),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  loc.currentScore(
                                    widget.battleService.currentUser?.name ??
                                        "Me",
                                    myScore,
                                    opponentName ?? "Opponent",
                                    opponentScore,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Be Vietnam Pro',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    letterSpacing: 0,
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty || currentIndex >= questions.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = questions[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      body: SafeArea(
        child: Column(
          children: [
            // Custom TopAppBar
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF755700).withOpacity(0.1),
                    blurRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF755700)),
                    onPressed: () => Navigator.pop(context),
                    hoverColor: const Color(0xFFDCDDD7),
                  ),
                  const Text(
                    "BATTLE",
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 1.0,
                      color: Color(0xFF755700),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for centering title
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isClassicQuestion = question.type != 'gap_fill';
                  final compactBattleLayout =
                      isClassicQuestion && constraints.maxHeight < 620;

                  final content = Column(
                    children: [
                      // Timer & Round Header
                      Column(
                        children: [
                          SizedBox(
                            width: compactBattleLayout ? 68 : 96,
                            height: compactBattleLayout ? 68 : 96,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: 1.0,
                                  strokeWidth: compactBattleLayout ? 6 : 8,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFE2E3DD),
                                  ),
                                ),
                                TweenAnimationBuilder<double>(
                                  key: ValueKey(question.id),
                                  tween: Tween<double>(
                                    begin:
                                        remainingSeconds / question.timeLimit,
                                    end: remainingSeconds / question.timeLimit,
                                  ),
                                  duration: const Duration(milliseconds: 500),
                                  builder: (context, value, child) {
                                    return CircularProgressIndicator(
                                      value: value,
                                      strokeWidth:
                                          compactBattleLayout ? 6 : 8,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFDC003),
                                      ),
                                      backgroundColor: Colors.transparent,
                                    );
                                  },
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "${remainingSeconds}s",
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontWeight: FontWeight.w800,
                                          fontSize:
                                              compactBattleLayout ? 18 : 24,
                                          color: const Color(0xFF2D2F2C),
                                        ),
                                      ),
                                      if (!compactBattleLayout)
                                        const Text(
                                          "LEFT",
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                            color: Color(0xFF767773),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: compactBattleLayout ? 10 : 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E3DD),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "BATTLE ROUND ${currentIndex + 1}",
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 2.0,
                                color: Color(0xFF5A5C58),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: compactBattleLayout ? 16 : 32),

                      // Question Card
                      if (isClassicQuestion) ...[
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2D2F2C,
                                ).withOpacity(0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              Positioned(
                                top: -12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D6661),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    "CHOOSE ANSWER",
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      color: Color(0xFFBEFFF8),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(
                                  compactBattleLayout ? 20 : 32,
                                ),
                                child: Text(
                                  question.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: compactBattleLayout ? 18 : 22,
                                    height: compactBattleLayout ? 1.25 : 1.5,
                                    color: const Color(0xFF2D2F2C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: compactBattleLayout ? 14 : 32),
                      ],

                      // Options / Gap Fill
                      if (isClassicQuestion)
                        Expanded(
                          child: _buildQuestionWidget(
                            question,
                            compact: compactBattleLayout,
                            fillAvailable: true,
                          ),
                        )
                      else
                        _buildQuestionWidget(question),
                    ],
                  );

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      compactBattleLayout ? 16 : 24,
                      compactBattleLayout ? 16 : 32,
                      compactBattleLayout ? 16 : 24,
                      compactBattleLayout ? 12 : 24,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: isClassicQuestion
                              ? content
                              : SingleChildScrollView(child: content),
                        ),
                        SizedBox(height: compactBattleLayout ? 8 : 16),

                        // Scoreboard Bento
                        _buildScoreBoard(compact: compactBattleLayout),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
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

  Widget _buildScoreBoard({bool compact = false}) {
    final avatarSize = compact ? 36.0 : 48.0;
    final cardPadding = compact ? 10.0 : 16.0;
    final avatarBorderWidth = compact ? 3.0 : 4.0;
    final nameFontSize = compact ? 13.0 : 16.0;
    final scoreFontSize = compact ? 20.0 : 24.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // User Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E3DD), // surface-container-high
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -24,
                  right: -24,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDC003).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFDC003),
                          width: avatarBorderWidth,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: UserAvatar(
                        name: myName ?? "Me",
                        base64Image: myAvatar,
                        size: avatarSize,
                        borderRadius: 8,
                      ),
                    ),
                    SizedBox(width: compact ? 10 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.battleService.currentUser?.name ?? "Me",
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: nameFontSize,
                              color: const Color(0xFF2D2F2C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${scores["me"] ?? 0}",
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: scoreFontSize,
                              color: const Color(0xFF2D2F2C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: compact ? 10 : 16),

        // Opponent Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E9E3), // surface-container
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -24,
                  left: -24,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC4B4).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFADADA9),
                          width: avatarBorderWidth,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: UserAvatar(
                        name: opponentName ?? "Opponent",
                        base64Image: opponentAvatar,
                        size: avatarSize,
                        borderRadius: 8,
                      ),
                    ),
                    SizedBox(width: compact ? 10 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            opponentName ?? "Opponent",
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: nameFontSize,
                              color: const Color(0xFF2D2F2C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${scores["opponent"] ?? 0}",
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: scoreFontSize,
                              color: const Color(0xFF2D2F2C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionWidget(
    Question question, {
    bool compact = false,
    bool fillAvailable = false,
  }) {
    switch (question.type) {
      case "gap_fill":
        return GapFillWidget(
          key: ValueKey(question.id),
          question: question,
          onSubmit: (answers) => _submitGapFill(question, answers),
        );

      case "multiple_choice":
      default:
        return LayoutBuilder(
          builder: (context, constraints) {
            final options = question.options ?? [];
            final crossAxisSpacing = compact ? 10.0 : 16.0;
            final mainAxisSpacing = compact ? 10.0 : 16.0;
            final rowCount = (options.length / 2).ceil().clamp(1, 4).toInt();
            final availableHeight = fillAvailable && constraints.hasBoundedHeight
                ? constraints.maxHeight
                : double.infinity;
            final fittedItemExtent = availableHeight.isFinite
                ? (availableHeight - (mainAxisSpacing * (rowCount - 1))) /
                      rowCount
                : (compact ? 60.0 : 76.0);
            final itemExtent = fittedItemExtent
                .clamp(48.0, compact ? 68.0 : 84.0)
                .toDouble();

            return GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: !fillAvailable,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisExtent: itemExtent,
              ),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                return ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F1EC),
                        foregroundColor: const Color(0xFF2D2F2C),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 6 : 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ).copyWith(
                        overlayColor:
                            MaterialStateProperty.resolveWith<Color?>((
                              Set<MaterialState> states,
                            ) {
                              if (states.contains(MaterialState.hovered)) {
                                return const Color(0xFFFDC003).withOpacity(0.1);
                              }
                              if (states.contains(MaterialState.pressed)) {
                                return const Color(0xFFFDC003).withOpacity(0.2);
                              }
                              return null;
                            }),
                        side: MaterialStateProperty.resolveWith<BorderSide?>((
                          Set<MaterialState> states,
                        ) {
                          if (states.contains(MaterialState.hovered) ||
                              states.contains(MaterialState.pressed)) {
                            return BorderSide(
                              color: const Color(0xFFFDC003).withOpacity(0.3),
                              width: 2,
                            );
                          }
                          return const BorderSide(
                            color: Colors.transparent,
                            width: 2,
                          );
                        }),
                      ),
                  onPressed: () => answerQuestion(opt),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      opt,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 15 : 18,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
    }
  }

  void _submitGapFill(Question question, List<String> selectedAnswers) {
    if (gameOver) return;

    widget.battleService.sendAnswer(question.id, selectedAnswers);
    myAnswers[question.id] = selectedAnswers.join("|");

    _timer?.cancel();
    setState(() {
      currentIndex += 1;
      if (currentIndex >= questions.length) {
        iFinished = true;
      }
    });

    if (iFinished) {
      _onLocalFinished();
    } else {
      _startTimerForCurrentQuestion();
    }
  }
}
