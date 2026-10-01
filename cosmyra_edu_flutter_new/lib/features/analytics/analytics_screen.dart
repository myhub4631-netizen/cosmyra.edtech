import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_design_system.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Gradient Accent
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.heroGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.md,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Color(0xFF06B6D4), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance & Mastery Analytics',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your preparation progress across subjects, chapters, and topics.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Weekly Question Attempt Activity Line Chart Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppShadows.md,
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.show_chart_rounded, color: Color(0xFF4F46E5), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Weekly Question Attempt Activity',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: Color(0xFF16A34A), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '+24% this week',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (val, meta) => Text(
                              '${val.toInt()}',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (val.toInt() >= 0 && val.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    days[val.toInt()],
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 30),
                            FlSpot(1, 45),
                            FlSpot(2, 60),
                            FlSpot(3, 52),
                            FlSpot(4, 75),
                            FlSpot(5, 90),
                            FlSpot(6, 65),
                          ],
                          isCurved: true,
                          color: const Color(0xFF4F46E5),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: const Color(0xFF4F46E5),
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF4F46E5).withValues(alpha: 0.25),
                                const Color(0xFF4F46E5).withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Subject Accuracy Breakdown Header
          Text(
            'Subject Accuracy Breakdown',
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSubjectCard(
                  context,
                  name: 'Physics',
                  accuracy: 84.2,
                  questions: '180 Solved',
                  color: const Color(0xFF2563EB),
                  icon: Icons.bolt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubjectCard(
                  context,
                  name: 'Chemistry',
                  accuracy: 78.5,
                  questions: '150 Solved',
                  color: const Color(0xFF10B981),
                  icon: Icons.science_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubjectCard(
                  context,
                  name: 'Biology',
                  accuracy: 91.0,
                  questions: '150 Solved',
                  color: const Color(0xFFEC4899),
                  icon: Icons.eco_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Chapter Mastery Map Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppShadows.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Chapter Mastery Heatmap & Progress',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildChapterMasteryRow('Kinematics & Motion in 2D', 0.94, '94% Mastery', 'Mastered', const Color(0xFF10B981)),
                const SizedBox(height: 14),
                _buildChapterMasteryRow('Laws of Motion & Friction', 0.88, '88% Mastery', 'Strong', const Color(0xFF2563EB)),
                const SizedBox(height: 14),
                _buildChapterMasteryRow('Organic Hydrocarbons', 0.76, '76% Mastery', 'Moderate', const Color(0xFFF59E0B)),
                const SizedBox(height: 14),
                _buildChapterMasteryRow('Thermodynamics & Heat', 0.54, '54% Mastery', 'Needs Focus', const Color(0xFFEF4444)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context, {
    required String name,
    required double accuracy,
    required String questions,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              // Radial Micro-graphic
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: accuracy / 100,
                      backgroundColor: color.withValues(alpha: 0.15),
                      color: color,
                      strokeWidth: 3.5,
                    ),
                    Text(
                      '${accuracy.toInt()}%',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14.5, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('${accuracy.toStringAsFixed(1)}% Accuracy', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(questions, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildChapterMasteryRow(String title, double progress, String percentStr, String statusLabel, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF0F172A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: barColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$percentStr ($statusLabel)',
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: barColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF1F5F9),
            color: barColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
