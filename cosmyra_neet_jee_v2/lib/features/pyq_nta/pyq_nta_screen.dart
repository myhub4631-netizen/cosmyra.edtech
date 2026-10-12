import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'pyq_practice_screen.dart';

class PyqNtaScreen extends StatelessWidget {
  final String activeExam;
  final Function(List<QuestionModel> questions, int timerMinutes, bool isTestMode)? onStartSession;
  final Function(List<QuestionModel> questions)? onStartPractice;

  const PyqNtaScreen({
    Key? key,
    required this.activeExam,
    this.onStartSession,
    this.onStartPractice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PYQPracticeScreen(
      activeExam: activeExam,
      onStartPYQSession: onStartSession,
      onStartPractice: onStartPractice != null ? (qs, timer) => onStartPractice!(qs) : null,
    );
  }
}
