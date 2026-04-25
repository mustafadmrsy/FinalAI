class QuizQuestionModel {
  const QuizQuestionModel({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      question: json['question'] as String,
      options: (json['options'] as List).cast<String>(),
      correctIndex: (json['correct_index'] as num).toInt(),
      explanation: (json['explanation'] as String?) ?? '',
    );
  }
}
