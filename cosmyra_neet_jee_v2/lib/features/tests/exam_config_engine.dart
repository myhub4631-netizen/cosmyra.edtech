import 'dart:math' as math;

enum ExamType { neet, jeeMain, jeeAdvanced, general }

class CollegePrediction {
  final String collegeName;
  final String locationOrBranch;
  final int closingRank;
  final int requiredMarks;
  final String chanceLevel; // High, Good, Moderate, Low, Less Likely

  CollegePrediction({
    required this.collegeName,
    required this.locationOrBranch,
    required this.closingRank,
    required this.requiredMarks,
    required this.chanceLevel,
  });
}

class ExamPredictionModel {
  final ExamType examType;
  final String examName;
  final String rankTerm; // AIR, CRL, Rank
  final int estimatedScore;
  final int maxMarks;
  final double accuracy;
  final double percentile;
  final int estimatedRank;
  final int rankRangeMin;
  final int rankRangeMax;
  final int previousRank;
  final int rankImprovement;
  final int studentsAttempted;
  final int beatStudentsCount;
  final double beatPercentage;
  final String mainCollegeQuestion; // e.g. "Will You Get a Govt. Medical College?"
  final String chanceBannerTitle;
  final String chanceBannerSubtitle;
  final String chanceLevel; // High, Good, Moderate, Low
  final int chancePercentage;
  final List<CollegePrediction> collegeCutoffs;
  final int targetScore;
  final String targetAdvice;

  ExamPredictionModel({
    required this.examType,
    required this.examName,
    required this.rankTerm,
    required this.estimatedScore,
    required this.maxMarks,
    required this.accuracy,
    required this.percentile,
    required this.estimatedRank,
    required this.rankRangeMin,
    required this.rankRangeMax,
    required this.previousRank,
    required this.rankImprovement,
    required this.studentsAttempted,
    required this.beatStudentsCount,
    required this.beatPercentage,
    required this.mainCollegeQuestion,
    required this.chanceBannerTitle,
    required this.chanceBannerSubtitle,
    required this.chanceLevel,
    required this.chancePercentage,
    required this.collegeCutoffs,
    required this.targetScore,
    required this.targetAdvice,
  });
}

class ExamConfigEngine {
  static ExamPredictionModel calculatePredictions({
    required String testTitle,
    required double score,
    required double maxScore,
    required double accuracy,
    required int totalQuestions,
    required int attemptedCount,
  }) {
    final titleLower = testTitle.toLowerCase();

    ExamType examType = ExamType.general;
    if (titleLower.contains('neet') || titleLower.contains('biology') || titleLower.contains('medical')) {
      examType = ExamType.neet;
    } else if (titleLower.contains('advanced') || titleLower.contains('iit')) {
      examType = ExamType.jeeAdvanced;
    } else if (titleLower.contains('jee') || titleLower.contains('mains') || titleLower.contains('engineering')) {
      examType = ExamType.jeeMain;
    }

    final int calcMaxMarks = maxScore > 0 ? maxScore.round() : (totalQuestions * 4);
    final int calcScore = score.round();
    final double scoreRatio = calcMaxMarks > 0 ? (calcScore / calcMaxMarks).clamp(0.0, 1.0) : 0.0;

    // Percentile & Rank Estimation Logic
    final double percentile = (50.0 + (scoreRatio * 49.5) + (accuracy * 0.004)).clamp(1.0, 99.9);
    
    int poolSize = 2000000; // NEET & JEE Main pool ~20 Lakhs
    if (examType == ExamType.jeeAdvanced) poolSize = 180000;

    int estRank = ((1.0 - (percentile / 100.0)) * poolSize).round();
    estRank = math.max(1, estRank);

    int minRange = math.max(1, (estRank * 0.88).round());
    int maxRange = (estRank * 1.15).round();
    int prevRank = (estRank * 1.22).round() + 450;
    int improvement = prevRank - estRank;

    int totalStudents = 15;
    int beatStudents = (totalStudents * (percentile / 100.0)).round().clamp(1, totalStudents);
    double beatPct = percentile.clamp(50.0, 99.0);

    String examName = 'NEET UG';
    String rankTerm = 'AIR';
    String mainCollegeQuestion = 'Will You Get a Govt. Medical College?';
    List<CollegePrediction> cutoffs = [];
    int targetScore = 630;
    String targetAdvice = 'Aim for 630+ marks to maximize your chances for top Govt. Medical Colleges.';

    if (examType == ExamType.neet) {
      examName = 'NEET UG';
      rankTerm = 'AIR';
      mainCollegeQuestion = 'Will You Get a Govt. Medical College?';
      targetScore = calcMaxMarks == 720 ? 630 : math.min(calcMaxMarks, (calcScore + 40).clamp(120, calcMaxMarks));
      targetAdvice = 'Aim for $targetScore+ marks to maximize your chances for top Govt. Medical Colleges.';
      
      cutoffs = [
        CollegePrediction(collegeName: 'AIIMS Delhi', locationOrBranch: 'AIQ (Gen)', closingRank: 50, requiredMarks: 705, chanceLevel: calcScore >= 695 ? 'High' : 'Low'),
        CollegePrediction(collegeName: 'JIPMER Puducherry', locationOrBranch: 'AIQ (Gen)', closingRank: 250, requiredMarks: 690, chanceLevel: calcScore >= 680 ? 'Good' : 'Low'),
        CollegePrediction(collegeName: 'Maulana Azad Medical College (Delhi)', locationOrBranch: 'AIQ', closingRank: 1200, requiredMarks: 665, chanceLevel: calcScore >= 655 ? 'Good' : 'Moderate'),
        CollegePrediction(collegeName: 'Government Medical College (Avg.)', locationOrBranch: 'State / AIQ', closingRank: 13000, requiredMarks: 605, chanceLevel: calcScore >= 595 ? 'High' : (calcScore >= 540 ? 'Moderate' : 'Less Likely')),
        CollegePrediction(collegeName: 'ESIC Medical College (Avg.)', locationOrBranch: 'AIQ', closingRank: 25000, requiredMarks: 585, chanceLevel: calcScore >= 575 ? 'High' : (calcScore >= 510 ? 'Moderate' : 'Less Likely')),
        CollegePrediction(collegeName: 'State Govt. Medical College (Avg.)', locationOrBranch: 'State Quota', closingRank: 40000, requiredMarks: 560, chanceLevel: calcScore >= 540 ? 'High' : 'Less Likely'),
      ];
    } else if (examType == ExamType.jeeMain) {
      examName = 'JEE Main';
      rankTerm = 'AIR';
      mainCollegeQuestion = 'Which Colleges Can You Get?';
      targetScore = calcMaxMarks == 300 ? 180 : math.min(calcMaxMarks, (calcScore + 30).clamp(60, calcMaxMarks));
      targetAdvice = 'Target $targetScore+ marks to improve your JEE Main percentile & NIT chances.';

      cutoffs = [
        CollegePrediction(collegeName: 'NIT Trichy', locationOrBranch: 'CSE / ECE', closingRank: 1500, requiredMarks: 240, chanceLevel: calcScore >= 230 ? 'High' : 'Low'),
        CollegePrediction(collegeName: 'NIT Surathkal / Warangal', locationOrBranch: 'Top Branches', closingRank: 3500, requiredMarks: 220, chanceLevel: calcScore >= 210 ? 'Good' : 'Low'),
        CollegePrediction(collegeName: 'IIIT Hyderabad', locationOrBranch: 'CSE / ECE', closingRank: 4200, requiredMarks: 215, chanceLevel: calcScore >= 205 ? 'Good' : 'Moderate'),
        CollegePrediction(collegeName: 'Top 10 NITs (Circuit Branches)', locationOrBranch: 'Other State', closingRank: 12000, requiredMarks: 180, chanceLevel: calcScore >= 170 ? 'High' : 'Moderate'),
        CollegePrediction(collegeName: 'Top NITs (Avg. Branch)', locationOrBranch: 'AIQ', closingRank: 25000, requiredMarks: 150, chanceLevel: calcScore >= 140 ? 'High' : 'Less Likely'),
        CollegePrediction(collegeName: 'State Govt. Engg. College (Avg.)', locationOrBranch: 'State Quota', closingRank: 50000, requiredMarks: 120, chanceLevel: calcScore >= 110 ? 'High' : 'Less Likely'),
      ];
    } else if (examType == ExamType.jeeAdvanced) {
      examName = 'JEE Advanced';
      rankTerm = 'AIR';
      mainCollegeQuestion = 'Which IITs Can You Get?';
      targetScore = calcMaxMarks == 360 ? 180 : math.min(calcMaxMarks, (calcScore + 30).clamp(60, calcMaxMarks));
      targetAdvice = 'Target $targetScore+ marks to improve your IIT chances.';

      cutoffs = [
        CollegePrediction(collegeName: 'IIT Bombay', locationOrBranch: 'CSE / Top Branch', closingRank: 300, requiredMarks: 260, chanceLevel: calcScore >= 250 ? 'High' : 'Low'),
        CollegePrediction(collegeName: 'IIT Delhi / IIT Kanpur', locationOrBranch: 'Top Branches', closingRank: 1000, requiredMarks: 220, chanceLevel: calcScore >= 210 ? 'Good' : 'Low'),
        CollegePrediction(collegeName: 'IIT Madras / IIT Kharagpur', locationOrBranch: 'Core Branches', closingRank: 2500, requiredMarks: 190, chanceLevel: calcScore >= 180 ? 'Good' : 'Moderate'),
        CollegePrediction(collegeName: 'Top 7 IITs (Avg. Branch)', locationOrBranch: 'Gen', closingRank: 6000, requiredMarks: 150, chanceLevel: calcScore >= 140 ? 'High' : 'Moderate'),
        CollegePrediction(collegeName: 'All IITs Cutoff (Avg.)', locationOrBranch: 'Gen', closingRank: 12000, requiredMarks: 120, chanceLevel: calcScore >= 110 ? 'High' : 'Less Likely'),
      ];
    } else {
      examName = 'Practice Test';
      rankTerm = 'Rank';
      mainCollegeQuestion = 'College Admission Predictor';
      targetScore = math.min(calcMaxMarks, (calcScore + 20).clamp(40, calcMaxMarks));
      targetAdvice = 'Target $targetScore+ marks to improve your overall test standing.';

      cutoffs = [
        CollegePrediction(collegeName: 'Top National Institutes', locationOrBranch: 'Gen', closingRank: 1000, requiredMarks: (calcMaxMarks * 0.85).round(), chanceLevel: scoreRatio >= 0.8 ? 'High' : 'Moderate'),
        CollegePrediction(collegeName: 'State Central Institutes', locationOrBranch: 'State', closingRank: 5000, requiredMarks: (calcMaxMarks * 0.65).round(), chanceLevel: scoreRatio >= 0.6 ? 'High' : 'Moderate'),
      ];
    }

    String chanceBannerTitle = 'Yes, You Can Get a Govt. Institute! 🎉';
    String chanceBannerSubtitle = 'At your current performance, you have a good chance.';
    String chanceLevel = 'High';
    int chancePercentage = 80;

    if (scoreRatio >= 0.75) {
      chanceBannerTitle = examType == ExamType.neet
          ? 'Yes, You Can Get a Govt. Medical College! 🎉'
          : (examType == ExamType.jeeAdvanced ? 'High Chance for Top IITs! 🏆' : 'High Chance for Top NITs & IIITs! 🌟');
      chanceBannerSubtitle = 'At your current performance, you have a strong competitive standing.';
      chanceLevel = 'High';
      chancePercentage = (scoreRatio * 100).round().clamp(75, 98);
    } else if (scoreRatio >= 0.55) {
      chanceBannerTitle = 'Good Chance for Top Institutes! 🌟';
      chanceBannerSubtitle = 'You are in a promising position. Keep practicing to secure your target cutoff.';
      chanceLevel = 'Good';
      chancePercentage = (scoreRatio * 100).round().clamp(55, 74);
    } else if (scoreRatio >= 0.35) {
      chanceBannerTitle = 'Moderate Standing - Keep Pushing! 🎯';
      chanceBannerSubtitle = 'With dedicated revision on weak topics, you can push into the top rank tiers.';
      chanceLevel = 'Moderate';
      chancePercentage = (scoreRatio * 100).round().clamp(35, 54);
    } else {
      chanceBannerTitle = 'Build Up Your Score Standard 🚀';
      chanceBannerSubtitle = 'Consistent practice will significantly boost your score and rank predictor.';
      chanceLevel = 'Low';
      chancePercentage = (scoreRatio * 100).round().clamp(15, 34);
    }

    return ExamPredictionModel(
      examType: examType,
      examName: examName,
      rankTerm: rankTerm,
      estimatedScore: calcScore,
      maxMarks: calcMaxMarks,
      accuracy: accuracy,
      percentile: percentile,
      estimatedRank: estRank,
      rankRangeMin: minRange,
      rankRangeMax: maxRange,
      previousRank: prevRank,
      rankImprovement: improvement,
      studentsAttempted: totalStudents,
      beatStudentsCount: beatStudents,
      beatPercentage: beatPct,
      mainCollegeQuestion: mainCollegeQuestion,
      chanceBannerTitle: chanceBannerTitle,
      chanceBannerSubtitle: chanceBannerSubtitle,
      chanceLevel: chanceLevel,
      chancePercentage: chancePercentage,
      collegeCutoffs: cutoffs,
      targetScore: targetScore,
      targetAdvice: targetAdvice,
    );
  }
}
