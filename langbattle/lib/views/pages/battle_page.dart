import 'package:flutter/material.dart';
import 'package:langbattle/objects/question.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/extensions/context_extensions.dart';
import 'dart:async';
import 'package:langbattle/widgets/gap_fill_widget.dart';


class BattleScreen extends StatefulWidget {
  final BattleService battleService;
  final String language;
  const BattleScreen({super.key, required this.battleService, required this.language});


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
  int? ratingDelta;
  int? newRating;
  String? newLevel;

  @override
  void initState() {
    super.initState();

    widget.battleService.joinQueue(language: widget.language);  

    widget.battleService.stream.listen((data) {
      if (data["type"] == "player_event") {
        final payload = data["payload"] as Map<String, dynamic>?;
        if (payload == null) return;
        final String? action = payload["action"]?.toString();
        final String? playerId = payload["playerId"]?.toString();
        final String? myId = widget.battleService.currentUser?.userId;

        // Opponent answered a question
        if (action == "answer" && playerId != null && playerId != myId) {
          setState(() {
            scores["opponent"] = (scores["opponent"] ?? 0) + 1; 
          });
        }

        // Opponent finished all questions
        if ((action == "finished" || action == "finish") &&
            playerId != null &&
            playerId != myId) {
          setState(() {
            opponentFinished = true;
          });
          _maybeEndGame();
        }
      }

      if (data["type"] == "match_found") {
        print("Match found: ${data["roomId"]}");
        final players = data["players"] as List<dynamic>;
        print("Players data: $players");
        final opponent = players.firstWhere((p) => p["id"] != widget.battleService.socketId);
        questions = (data["questions"] as List)
            .map((q) => Question.fromJson(q))
            .toList();
        
        print("Opponent data: $opponent");
        print("Opponent keys: ${opponent.keys}");

        setState(() {
          isWaitingForOpponent = false;
          widget.battleService.roomId = data["roomId"];
          opponentName = opponent["name"];
          currentIndex = 0;
          iFinished = false;
          opponentFinished = false;
          gameOver = false;
        });
        _startTimerForCurrentQuestion();
      }

        if (data["type"] == "rating_updated") {
        final d = data["data"] as Map;
        setState(() {
          ratingDelta = d["delta"] as int?;
          newRating = d["newRating"] as int?;
          newLevel = d["newLevel"]?.toString();
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
    super.dispose();
  }

  void answerQuestion(String answer) {
    if (currentIndex >= questions.length || gameOver) return;

    final question = questions[currentIndex];

    // Update local score for me if correct
    if (question.correctAnswers?.contains(answer) == true) {
  setState(() {
    scores["me"] = (scores["me"] ?? 0) + 1;
  });
}

    widget.battleService.sendAnswer(question.id, answer);

    // Move to next question or finish
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

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    // Waiting for opponent before match starts
    if (isWaitingForOpponent) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.battleService.disconnect();
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
    }

    // Game over for both players
    if (gameOver) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.gameOverSummary(
                  widget.battleService.currentUser?.name ?? "Me",
                  scores["me"] ?? 0,
                  opponentName ?? "Opponent",
                  scores["opponent"] ?? 0,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
              ),
              if (ratingDelta != null) ...[
                const SizedBox(height: 12),
                Text(
                  ratingDelta! >= 0
                      ? '+$ratingDelta pts → $newRating ($newLevel)'
                      : '$ratingDelta pts → $newRating ($newLevel)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ratingDelta! >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
                            const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(loc.returnToHome),
              ),
            ],
          ),
        ),
      );
    }

    // I have finished, but opponent is still playing
    if (iFinished && !opponentFinished) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.youFinishedWaitingOpponent,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Text(
                loc.currentScore(
                  widget.battleService.currentUser?.name ?? "Me",
                  scores["me"] ?? 0,
                  opponentName ?? "Opponent",
                  scores["opponent"] ?? 0,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // Defensive: if there are no questions yet
    if (questions.isEmpty || currentIndex >= questions.length) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final question = questions[currentIndex];

    // Game in progress
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.battleRound(currentIndex + 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question.text, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 16),
        Text(
          loc.timeLeft(remainingSeconds),
          style: const TextStyle(fontSize: 18, color: Colors.red),
        ),
        const SizedBox(height: 16),

        _buildQuestionWidget(question),

        const SizedBox(height: 20),
        Text(
          loc.scoreLine(
            widget.battleService.currentUser?.name ?? "Me",
            scores["me"] ?? 0,
            opponentName ?? "Opponent",
            scores["opponent"] ?? 0,
          ),
          style: const TextStyle(fontSize: 18),
        ),
      ],
    ),
    );
  }

  Widget _buildQuestionWidget(Question question) {
  switch (question.type) {
    case "gap_fill":
      return GapFillWidget(
        key: ValueKey(question.id),
        question: question,
        onSubmit: (answers) => _submitGapFill(question, answers),
      );

    case "multiple_choice":
    default:
      return Column(
        children: question.options!.map((opt) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 16),
            child: ElevatedButton(
              onPressed: () => answerQuestion(opt),
              child: Text(opt),
            ),
          );
        }).toList(),
      );
  }
}
void _submitGapFill(Question question, List<String> selectedAnswers) {
  if (gameOver) return;

  bool isCorrect = true;

  if (selectedAnswers.length != question.correctAnswers!.length) {
    isCorrect = false;
  } else {
    for (int i = 0; i < selectedAnswers.length; i++) {
      if (selectedAnswers[i] != question.correctAnswers![i]) {
        isCorrect = false;
        break;
      }
    }
  }

  if (isCorrect) {
    setState(() {
      scores["me"] = (scores["me"] ?? 0) + 1;
    });
  }

  widget.battleService.sendAnswer(question.id, selectedAnswers);

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
