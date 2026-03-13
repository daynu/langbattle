import 'package:flutter/material.dart';
import 'package:langbattle/objects/question.dart';

class ReviewAnswersScreen extends StatelessWidget {
  final List<Question> questions;
  final Map<String, String> myAnswers; // questionId -> answer given (empty = skipped)

  const ReviewAnswersScreen({
    super.key,
    required this.questions,
    required this.myAnswers,
  });

  List<Question> get _wrongOrSkipped {
    return questions.where((q) {
      final given = myAnswers[q.id] ?? "";
      final correct = q.correctAnswers ?? [];
      if (given.isEmpty) return true;
      final givenParts = given.split("|");
      if (givenParts.length == correct.length) {
        for (int i = 0; i < correct.length; i++) {
          if (givenParts[i] != correct[i]) return true;
        }
        return false;
      }
      return !correct.contains(given);
    }).toList();
  }

  String _displayAnswer(String raw) {
    if (raw.isEmpty) return "Skipped";
    return raw.replaceAll("|", ", ");
  }

  @override
  Widget build(BuildContext context) {
    final wrong = _wrongOrSkipped;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Answers"),
      ),
      body: wrong.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_rounded,
                      size: 64, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    "Perfect score!",
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You got every question right.",
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: wrong.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final q = wrong[index];
                final given = myAnswers[q.id] ?? "";
                final correct = (q.correctAnswers ?? []).join(", ");
                final skipped = given.isEmpty;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number + text
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Q${index + 1}",
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q.text,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Your answer
                        _AnswerRow(
                          label: "Your answer",
                          value: skipped ? "Skipped" : _displayAnswer(given),
                          color: skipped
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.error,
                          icon: skipped
                              ? Icons.remove_circle_outline
                              : Icons.close_rounded,
                        ),

                        const SizedBox(height: 6),

                        // Correct answer
                        _AnswerRow(
                          label: "Correct answer",
                          value: correct,
                          color: Colors.green.shade600,
                          icon: Icons.check_circle_outline_rounded,
                        ),

                        // Explanation
                        if (q.explanation != null &&
                            q.explanation!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              q.explanation!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _AnswerRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}