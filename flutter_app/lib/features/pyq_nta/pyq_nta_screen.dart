import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'nta_practice_test_screen.dart';

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
    return NtaPracticeTestScreen(
      activeExam: activeExam,
      onStartSession: onStartSession,
      onStartPractice: onStartPractice,
    );
  }
}
