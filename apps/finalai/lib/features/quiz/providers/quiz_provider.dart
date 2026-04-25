import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/quiz_model.dart';
import '../../../core/repositories/game_repository.dart';
import '../../../core/repositories/repository_providers.dart';

class QuizState {
  const QuizState({
    required this.isLoading,
    this.errorMessage,
    required this.questions,
    this.currentIndex = 0,
    this.correctCount = 0,
    this.selectedIndex,
    this.isFinished = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<QuizQuestionModel> questions;
  final int currentIndex;
  final int correctCount;
  final int? selectedIndex;
  final bool isFinished;

  QuizQuestionModel? get currentQuestion {
    if (questions.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  int get total => questions.length;

  QuizState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<QuizQuestionModel>? questions,
    int? currentIndex,
    int? correctCount,
    int? selectedIndex,
    bool clearSelectedIndex = false,
    bool? isFinished,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      selectedIndex: clearSelectedIndex ? null : (selectedIndex ?? this.selectedIndex),
      isFinished: isFinished ?? this.isFinished,
    );
  }

  static const idle = QuizState(isLoading: false, questions: []);
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(this._gameRepository) : super(QuizState.idle) {
    loadSample();
  }

  final GameRepository _gameRepository;

  String? _noteId;

  void loadFromNoteQuestions(List<dynamic> questionsJson) {
    try {
      final questions = questionsJson
          .map((e) => QuizQuestionModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        questions: questions,
        currentIndex: 0,
        correctCount: 0,
        clearSelectedIndex: true,
        isFinished: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void setNoteId(String? noteId) {
    _noteId = noteId;
  }

  void loadSample() {
    state = state.copyWith(
      isLoading: false,
      errorMessage: null,
      questions: const [
        QuizQuestionModel(
          question: 'Elektrik alanın birimi nedir?',
          options: ['A) Volt', 'B) Newton/Coulomb', 'C) Watt', 'D) Ohm'],
          correctIndex: 1,
          explanation: 'Elektrik alan birimi N/C (veya V/m) olarak ifade edilir.',
        ),
        QuizQuestionModel(
          question: 'Ohm kanunu aşağıdakilerden hangisidir?',
          options: ['A) V = I/R', 'B) V = I·R', 'C) I = V·R', 'D) R = V·I'],
          correctIndex: 1,
          explanation: 'Ohm kanunu: V = I·R',
        ),
      ],
      currentIndex: 0,
      correctCount: 0,
      selectedIndex: null,
      isFinished: false,
    );
  }

  void selectAnswer(int index) {
    if (state.isFinished) return;
    if (state.selectedIndex != null) return;
    state = state.copyWith(selectedIndex: index);

    final q = state.currentQuestion;
    if (q == null) return;

    final isCorrect = index == q.correctIndex;
    if (isCorrect) {
      state = state.copyWith(correctCount: state.correctCount + 1);
    }
  }

  void next() {
    if (state.isFinished) return;
    if (state.questions.isEmpty) return;

    final isLast = state.currentIndex >= state.questions.length - 1;
    if (isLast) {
      state = state.copyWith(isFinished: true);

      final noteId = _noteId;
      if (noteId != null) {
        _gameRepository.createGameSession(
          noteId: noteId,
          totalQuestions: state.questions.length,
          correctAnswers: state.correctCount,
        );
      }
      return;
    }

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      clearSelectedIndex: true,
    );
  }

  void restart() {
    state = state.copyWith(
      currentIndex: 0,
      correctCount: 0,
      clearSelectedIndex: true,
      isFinished: false,
    );
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (ref) => QuizNotifier(ref.watch(gameRepositoryProvider)),
);
