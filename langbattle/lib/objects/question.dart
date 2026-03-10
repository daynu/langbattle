class Question {
  final String id;
  final String text;
  final String type; // "multiple_choice", "fill_blank", "translation", etc.
  final int timeLimit;

  // Optional fields depending on type
  final List<String>? options; 
  final List<String>? correctAnswers;
  final String? mediaUrl; // for audio/image later
  final Map<String, dynamic>? metadata; // for future expansion

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.timeLimit = 10,
    this.options,
    this.correctAnswers,
    this.mediaUrl,
    this.metadata,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? json['_id'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? 'multiple_choice',
      timeLimit: json['timeLimit'] ?? 10,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      correctAnswers: json['correctAnswers'] != null
    ? List<String>.from(json['correctAnswers'])
    : json['correctAnswer'] != null
        ? [json['correctAnswer'].toString()]
        : null,  // empty list instead of null,
      mediaUrl: json['mediaUrl'],
      metadata: json['metadata'],
    );
  }
}