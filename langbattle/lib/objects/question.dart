class Question {
  final String id;
  final String text;
  final List<String> options;
  final int timeLimit;
  /// The correct option text (must match one of [options] exactly for validation).
  final String correctAnswer;

  Question({
    required this.id,
    required this.text,
    required this.options,
    this.timeLimit = 10,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Server may send MongoDB _id or plain id
    final id = json['id'] ?? json['_id'];
    final options = List<String>.from(json['options'] ?? []);
    // correctAnswer can be sent directly, or derived from correctIndex
    String correctAnswer = json['correctAnswer']?.toString() ?? '';
    if (correctAnswer.isEmpty && json['correctIndex'] != null) {
      final idx = (json['correctIndex'] is int) ? json['correctIndex'] as int : int.tryParse(json['correctIndex'].toString());
      if (idx != null && idx >= 0 && idx < options.length) correctAnswer = options[idx];
    }
    return Question(
      id: id?.toString() ?? '',
      text: json['text'] ?? 'Unknown question',
      options: options,
      timeLimit: json['timeLimit'] ?? 10,
      correctAnswer: correctAnswer,
    );
  }
}

