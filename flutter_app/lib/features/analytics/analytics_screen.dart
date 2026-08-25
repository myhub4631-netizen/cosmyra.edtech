import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Text('Performance & Mastery Analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Track your preparation progress across subjects, chapters, and topics.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),

          // Daily Questions Attempted Line Chart Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Question Attempt Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (val.toInt() >= 0 && val.toInt() < days.length) {
                                  return Text(days[val.toInt()], style: const TextStyle(fontSize: 11, color: Colors.grey));
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
                              FlSpot(6, 45),
                            ],
                            isCurved: true,
                            color: Theme.of(context).primaryColor,
                            barWidth: 3.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).primaryColor.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Subject Accuracy Breakdown
          Text('Subject Accuracy Breakdown', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSubjectCard(context, name: 'Physics', accuracy: '84.2%', questions: '180 Solved', color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubjectCard(context, name: 'Chemistry', accuracy: '78.5%', questions: '150 Solved', color: const Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubjectCard(context, name: 'Biology', accuracy: '91.0%', questions: '150 Solved', color: Colors.pink),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Chapter Mastery Map Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chapter Mastery Heatmap & Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildChapterMasteryRow('Kinematics & Motion in 2D', 0.94, '94% Mastery (Mastered)'),
                  const SizedBox(height: 12),
                  _buildChapterMasteryRow('Laws of Motion & Friction', 0.88, '88% Mastery (Strong)'),
                  const SizedBox(height: 12),
                  _buildChapterMasteryRow('Organic Hydrocarbons', 0.76, '76% Mastery (Moderate)'),
                  const SizedBox(height: 12),
                  _buildChapterMasteryRow('Thermodynamics & Heat', 0.54, '54% Mastery (Needs Focus)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, {required String name, required String accuracy, required String questions, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(accuracy, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(questions, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterMasteryRow(String title, double progress, String label) {
    Color barColor = Colors.green;
    if (progress < 0.6) barColor = Colors.orange;
    if (progress < 0.4) barColor = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: barColor)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          color: barColor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
