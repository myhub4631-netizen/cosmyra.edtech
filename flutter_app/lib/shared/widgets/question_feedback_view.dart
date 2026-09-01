import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../services/audio_feedback_service.dart';
import 'latex_view.dart';
import 'smart_image.dart';

class QuestionFeedbackView extends StatefulWidget {
  final QuestionModel question;
  final int questionIndex;
  final int totalQuestions;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final bool isPartial;
  final int currentStreak;
  final double currentScore;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onNextQuestion;
  final bool isLastQuestion;
  final bool isAudioMuted;
  final VoidCallback onToggleAudio;
  final VoidCallback? onBookmarkToggle;
  final bool isBookmarked;
  final VoidCallback? onReportQuestion;

  const QuestionFeedbackView({
    super.key,
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    this.isPartial = false,
    required this.currentStreak,
    required this.currentScore,
    required this.onOptionSelected,
    required this.onNextQuestion,
    this.isLastQuestion = false,
    required this.isAudioMuted,
    required this.onToggleAudio,
    this.onBookmarkToggle,
    this.isBookmarked = false,
    this.onReportQuestion,
  });

  @override
  State<QuestionFeedbackView> createState() => _QuestionFeedbackViewState();
}

class _QuestionFeedbackViewState extends State<QuestionFeedbackView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final FocusNode _focusNode = FocusNode();

  static const List<String> _correctMessages = [
    "Great job! Keep going! 🎉",
    "Excellent! You're on a streak! 🔥",
    "Spot on! Concept mastered! 🌟",
    "Brilliant problem solving! 👏",
    "Perfect answer! Stay sharp! ⚡",
  ];

  static const List<String> _incorrectMessages = [
    "Not quite! One mistake doesn't define your score 💪",
    "You can get the next one! Keep trying! 🚀",
    "Good effort! Learn from this step and conquer 💡",
    "Don't worry, practice builds perfection! 📈",
  ];

  late String _motivationalText;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _setRandomMessage();
    AudioFeedbackService.init();
  }

  @override
  void didUpdateWidget(covariant QuestionFeedbackView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isAnswered && widget.isAnswered) {
      _animController.forward(from: 0.0);
      _setRandomMessage();
      if (widget.isCorrect) {
        if (widget.currentStreak > 1) {
          AudioFeedbackService.playStreakSound(widget.currentStreak);
        } else {
          AudioFeedbackService.playCorrectSound();
        }
      } else {
        AudioFeedbackService.playIncorrectSound();
      }
    }
  }

  void _setRandomMessage() {
    final rand = Random();
    if (widget.isCorrect) {
      _motivationalText = _correctMessages[rand.nextInt(_correctMessages.length)];
    } else {
      _motivationalText = _incorrectMessages[rand.nextInt(_incorrectMessages.length)];
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isOptSelected(String optKey, String optLetter, String optText) {
    if (widget.selectedAnswer == null || widget.selectedAnswer!.isEmpty) return false;
    final parts = widget.selectedAnswer!.split(',');
    for (var p in parts) {
      final trimmed = p.trim();
      if (trimmed == optKey) return true;
      if (trimmed == optLetter || trimmed == 'Option $optLetter') return true;
      if (optText.isNotEmpty && trimmed == optText) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final isAnswered = widget.isAnswered;
    final isCorrect = widget.isCorrect;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) {
        if (event is RawKeyDownEvent && isAnswered) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onNextQuestion();
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. COMPACT PROGRESS HEADER & AUDIO TOGGLE
          _buildProgressHeader(),

          const SizedBox(height: 14),

          // 2. STREAK MILESTONE BANNER (IF ACTIVE STREAK >= 2)
          if (widget.currentStreak >= 2) _buildStreakMilestoneBanner(),

          const SizedBox(height: 12),

          // 3. QUESTION TEXT & IMAGE CARD
          _buildQuestionCard(question),

          const SizedBox(height: 18),

          // 4. OPTIONS LIST
          ...question.options.map((opt) {
            final String optKey = (opt.id != null && opt.id.isNotEmpty) ? opt.id : 'opt_${question.id}_${opt.optionIndex}';
            final String optLetter = String.fromCharCode(65 + opt.optionIndex);
            final String optionText = opt.optionText;
            final bool isSelected = _isOptSelected(optKey, optLetter, optionText);
            final bool isThisCorrect = opt.isCorrect;

            Color borderColor = const Color(0xFFE2E8F0);
            Color bgColor = Colors.white;

            if (isAnswered) {
              if (isThisCorrect) {
                borderColor = const Color(0xFF10B981);
                bgColor = const Color(0xFFECFDF5);
              } else if (isSelected && !isThisCorrect) {
                borderColor = const Color(0xFFEF4444);
                bgColor = const Color(0xFFFEF2F2);
              }
            } else if (isSelected) {
              borderColor = const Color(0xFF2563EB);
              bgColor = const Color(0xFFEFF6FF);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: isAnswered ? null : () => widget.onOptionSelected(opt.optionIndex),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: (isAnswered && (isThisCorrect || isSelected)) || isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isAnswered && isThisCorrect
                            ? const Color(0xFF10B981)
                            : (isAnswered && isSelected && !isThisCorrect
                                ? const Color(0xFFEF4444)
                                : (isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9))),
                        child: Text(
                          optLetter,
                          style: TextStyle(
                            color: isAnswered && (isThisCorrect || isSelected) || isSelected ? Colors.white : const Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (optionText.isNotEmpty) LaTeXView(text: optionText),
                            if (opt.optionImage != null && opt.optionImage!.isNotEmpty) ...[
                              if (optionText.isNotEmpty) const SizedBox(height: 6),
                              SmartImage(
                                url: opt.optionImage,
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isAnswered && isThisCorrect)
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                        )
                      else if (isAnswered && isSelected && !isThisCorrect)
                        const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          // 5. IMMEDIATE FEEDBACK & MOTIVATION BOX
          if (isAnswered) ...[
            const SizedBox(height: 14),
            _buildFeedbackBox(question, isCorrect),
          ],

          const SizedBox(height: 24),

          // 6. PROMINENT NEXT QUESTION BUTTON
          if (isAnswered) _buildNextQuestionButton(),
        ],
      ),
    );
  }

  // Header Bar
  Widget _buildProgressHeader() {
    final double progress = (widget.questionIndex + 1) / widget.totalQuestions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Question ${widget.questionIndex + 1}/${widget.totalQuestions}',
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    'Score ${widget.currentScore.toInt()}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                  ),
                  if (widget.currentStreak > 0) ...[
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.currentStreak} Streak',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFEA580C)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Audio Toggle Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  widget.isAudioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: widget.isAudioMuted ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
                  size: 20,
                ),
                tooltip: widget.isAudioMuted ? 'Unmute Sound' : 'Mute Sound',
                onPressed: widget.onToggleAudio,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  // Streak Banner
  Widget _buildStreakMilestoneBanner() {
    String milestoneText = '🔥 ${widget.currentStreak} in a row!';
    if (widget.currentStreak >= 10) {
      milestoneText = '🏆 10-Question Streak! Unstoppable!';
    } else if (widget.currentStreak >= 5) {
      milestoneText = '🔥 5 Correct in a row! Amazing Momentum!';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            milestoneText,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFC2410C)),
          ),
        ],
      ),
    );
  }

  // Question Card
  Widget _buildQuestionCard(QuestionModel question) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: question.difficulty == 'easy'
                          ? const Color(0xFFDCFCE7)
                          : (question.difficulty == 'hard' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      question.difficulty.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: question.difficulty == 'easy'
                            ? const Color(0xFF16A34A)
                            : (question.difficulty == 'hard' ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded, size: 12, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 4),
                        Text(
                          question.displaySource,
                          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF1D4ED8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (widget.onBookmarkToggle != null)
                    IconButton(
                      icon: Icon(
                        widget.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: widget.isBookmarked ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: widget.onBookmarkToggle,
                    ),
                  if (widget.onReportQuestion != null)
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, color: Color(0xFF94A3B8), size: 20),
                      onPressed: widget.onReportQuestion,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LaTeXView(
            text: question.questionText,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A), height: 1.4),
          ),
          if (question.questionImage != null) ...[
            const SizedBox(height: 12),
            SmartImage(
              url: question.questionImage,
              height: 180,
              fit: BoxFit.contain,
            ),
          ],
        ],
      ),
    );
  }

  // Feedback Box
  Widget _buildFeedbackBox(QuestionModel question, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
                color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _motivationalText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),

          if (question.explanation != null && question.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 10),
            Text(
              'Explanation:',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 4),
            LaTeXView(text: question.explanation!),
          ],

          if (question.solution != null && question.solution!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Solution:',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 4),
            LaTeXView(text: question.solution!),
          ],
        ],
      ),
    );
  }

  // Next Question Button
  Widget _buildNextQuestionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: widget.onNextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isLastQuestion ? 'Finish Practice Session 🎉' : 'Next Question',
              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
