import 'package:flutter/material.dart';
import '../objects/question.dart';

class GapFillWidget extends StatefulWidget {
  final Question question;
  final Function(List<String>) onSubmit;

  const GapFillWidget({
    super.key,
    required this.question,
    required this.onSubmit,
  });

  @override
  State<GapFillWidget> createState() => _GapFillWidgetState();
}

class _GapFillWidgetState extends State<GapFillWidget> {
  List<String> selectedAnswers = [];

  @override
  Widget build(BuildContext context) {
    final parts = widget.question.text.split("___");

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(parts.length, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(parts[index], style: const TextStyle(fontSize: 20)),
                if (index < parts.length - 1)
                  Container(
                    width: 80,
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Text(
                      selectedAnswers.length > index
                          ? selectedAnswers[index]
                          : "___",
                    ),
                  ),
              ],
            );
          }),
        ),

        const SizedBox(height: 20),

        Wrap(
          spacing: 8,
          children: widget.question.options!.map((option) {
            return ElevatedButton(
              onPressed: () {
                if (!selectedAnswers.contains(option)) {
                  setState(() {
                    selectedAnswers.add(option);
                  });
                }
              },
              child: Text(option),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () {
            widget.onSubmit(selectedAnswers);
          },
          child: const Text("Submit"),
        )
      ],
    );
  }
}