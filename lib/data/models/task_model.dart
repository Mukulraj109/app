class DailyTask {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final String timeEstimate;

  const DailyTask({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.timeEstimate,
  });

  DailyTask copyWith({bool? isCompleted}) {
    return DailyTask(
      id: id,
      title: title,
      description: description,
      timeEstimate: timeEstimate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class QuestionOfTheDay {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final int currentStreak;
  final bool isAnswered;
  final int? selectedOption;

  const QuestionOfTheDay({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.currentStreak,
    this.isAnswered = false,
    this.selectedOption,
  });

  QuestionOfTheDay copyWith({
    bool? isAnswered,
    int? selectedOption,
    int? currentStreak,
  }) {
    return QuestionOfTheDay(
      id: id,
      question: question,
      options: options,
      correctOptionIndex: correctOptionIndex,
      currentStreak: currentStreak ?? this.currentStreak,
      isAnswered: isAnswered ?? this.isAnswered,
      selectedOption: selectedOption ?? this.selectedOption,
    );
  }
}

class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final int minutes;
  final bool isCompleted;

  const WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.minutes,
    this.isCompleted = false,
  });

  WeeklyChallenge copyWith({bool? isCompleted}) {
    return WeeklyChallenge(
      id: id,
      title: title,
      description: description,
      minutes: minutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
