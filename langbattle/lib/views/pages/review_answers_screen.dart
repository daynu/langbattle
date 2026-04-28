import 'package:flutter/material.dart';
import 'package:langbattle/objects/question.dart';

class ReviewAnswersScreen extends StatelessWidget {
  final List<Question> questions;
  final Map<String, String> myAnswers;

  const ReviewAnswersScreen({
    super.key,
    required this.questions,
    required this.myAnswers,
  });

  bool _isSkipped(Question question) {
    return (myAnswers[question.id] ?? "").trim().isEmpty;
  }

  bool _isCorrect(Question question) {
    final given = (myAnswers[question.id] ?? "").trim();
    final correct = question.correctAnswers ?? [];
    if (given.isEmpty || correct.isEmpty) return false;

    final givenParts = given.split("|").map((part) => part.trim()).toList();
    final correctParts = correct.map((part) => part.trim()).toList();

    if (given.contains("|") ||
        question.type == "gap_fill" ||
        correctParts.length > 1) {
      if (givenParts.length != correctParts.length) return false;
      for (int i = 0; i < correctParts.length; i++) {
        if (givenParts[i] != correctParts[i]) return false;
      }
      return true;
    }

    return correctParts.contains(given);
  }

  String _displayAnswer(String raw) {
    if (raw.trim().isEmpty) return "Skipped";
    return raw.split("|").map((part) => part.trim()).join(", ");
  }

  String _displayCorrectAnswer(Question question) {
    final correct = question.correctAnswers ?? [];
    if (correct.isEmpty) return "Not available";
    return correct.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final correctCount = questions.where(_isCorrect).length;

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
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF5A5C58),
                    ),
                    onPressed: () => Navigator.pop(context),
                    hoverColor: const Color(0xFFDCDDD7),
                  ),
                  const Text(
                    "Review Answers",
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
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                itemCount: questions.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ReviewSummary(
                      correctCount: correctCount,
                      totalCount: questions.length,
                    );
                  }

                  final questionIndex = index - 1;
                  final question = questions[questionIndex];
                  final given = myAnswers[question.id] ?? "";
                  final skipped = _isSkipped(question);
                  final correct = _isCorrect(question);

                  return _QuestionReviewCard(
                    index: questionIndex + 1,
                    question: question,
                    givenAnswer: _displayAnswer(given),
                    correctAnswer: _displayCorrectAnswer(question),
                    skipped: skipped,
                    correct: correct,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  final int correctCount;
  final int totalCount;

  const _ReviewSummary({
    required this.correctCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasPerfectScore = totalCount > 0 && correctCount == totalCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F755700),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              hasPerfectScore
                  ? Icons.emoji_events_rounded
                  : Icons.fact_check_rounded,
              color: const Color(0xFF553E00),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Review",
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Color(0xFF553E00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$correctCount of $totalCount correct",
                  style: const TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF755700),
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

class _QuestionReviewCard extends StatelessWidget {
  final int index;
  final Question question;
  final String givenAnswer;
  final String correctAnswer;
  final bool skipped;
  final bool correct;

  const _QuestionReviewCard({
    required this.index,
    required this.question,
    required this.givenAnswer,
    required this.correctAnswer,
    required this.skipped,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = skipped
        ? const Color(0xFF767773)
        : correct
        ? const Color(0xFF0D6661)
        : const Color(0xFFB02500);
    final statusBackground = skipped
        ? const Color(0xFFE8E9E3)
        : correct
        ? const Color(0xFFE0F2EF)
        : const Color(0xFFFFE3DC);
    final statusText = skipped ? "SKIPPED" : (correct ? "CORRECT" : "MISSED");
    final statusIcon = skipped
        ? Icons.remove_circle_outline_rounded
        : correct
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8E9E3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2D2F2C),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1EC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "Q$index",
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF5A5C58),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.text,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.35,
                    color: Color(0xFF2D2F2C),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AnswerBlock(
            label: "Your answer",
            value: givenAnswer,
            color: statusColor,
            backgroundColor: statusBackground,
          ),
          const SizedBox(height: 10),
          _AnswerBlock(
            label: "Correct answer",
            value: correctAnswer,
            color: const Color(0xFF0D6661),
            backgroundColor: const Color(0xFFE0F2EF),
          ),
          if (question.explanation != null &&
              question.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                question.explanation!,
                style: const TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF5A5C58),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color backgroundColor;

  const _AnswerBlock({
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2,
              color: color.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
