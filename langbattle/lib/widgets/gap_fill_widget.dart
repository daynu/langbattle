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
          spacing: 8,
          runSpacing: 12,
          children: List.generate(parts.length * 2 - 1, (i) {
            if (i.isEven) {
              final text = parts[i ~/ 2].trim();
              if (text.isEmpty) return const SizedBox.shrink();
              return Text(
                text, 
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Color(0xFF2D2F2C),
                )
              );
            } else {
              final index = i ~/ 2;
              return Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: const Color(0xFFFDC003), width: 4)),
                ),
                child: Text(
                  selectedAnswers.length > index ? selectedAnswers[index] : "",
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFF755700),
                  ),
                ),
              );
            }
          }),
        ),

        const SizedBox(height: 32),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: (widget.question.options ?? []).map((option) {
            final isSelected = selectedAnswers.contains(option);
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFFE2E3DD) : const Color(0xFFF1F1EC),
                foregroundColor: const Color(0xFF2D2F2C),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.transparent, width: 2),
                ),
              ),
              onPressed: () {
                if (!isSelected) {
                  setState(() {
                    selectedAnswers.add(option);
                  });
                }
              },
              child: Text(
                option,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        InkWell(
          onTap: () => widget.onSubmit(selectedAnswers),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFDC003),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF755700),
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: const Text(
              "SUBMIT ANSWER",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2.0,
                color: Color(0xFF553E00),
              ),
            ),
          ),
        )
      ],
    );
  }
}