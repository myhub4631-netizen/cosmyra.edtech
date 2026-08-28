import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'pyq_practice_screen.dart';

class PyqNtaScreen extends StatelessWidget {
  final String activeExam;
  final Function(List<QuestionModel> questions) onStartPractice;

  const PyqNtaScreen({
    Key? key,
    required this.activeExam,
    required this.onStartPractice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PYQPracticeScreen(
      activeExam: activeExam,
      onStartPractice: (questions, timerMins) {
        onStartPractice(questions);
      },
    );
  }
}
