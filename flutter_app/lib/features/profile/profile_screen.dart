import 'package:flutter/material.dart';
import '../../models/models.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfileModel userProfile;
  final String activeExam;
  final ValueChanged<String> onExamChanged;
  final VoidCallback onSignOut;

  const ProfileScreen({
    Key? key,
    required this.userProfile,
    required this.activeExam,
    required this.onExamChanged,
    required this.onSignOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Identity Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      userProfile.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(userProfile.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: userProfile.isAdmin ? Colors.redAccent : Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                userProfile.role.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(userProfile.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('Target: $activeExam ${userProfile.targetYear}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Exam Target Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Competitive Exam Preference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: activeExam,
                    decoration: const InputDecoration(labelText: 'Active Exam Target'),
                    items: const [
                      DropdownMenuItem(value: 'NEET', child: Text('NEET UG (Medical Entrance)')),
                      DropdownMenuItem(value: 'JEE_MAIN', child: Text('JEE Main (Engineering)')),
                      DropdownMenuItem(value: 'JEE_ADV', child: Text('JEE Advanced (IIT Admission)')),
                    ],
                    onChanged: (val) {
                      if (val != null) onExamChanged(val);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Preparation Stats Summary Grid
          Text('Study Statistics & Achievements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatBox(context, 'Study Streak', '${userProfile.studyStreak} Days 🔥', Colors.orange),
              _buildStatBox(context, 'Questions Solved', '${userProfile.questionsAttempted}', Colors.blue),
              _buildStatBox(context, 'Accuracy %', '${userProfile.accuracy}%', Colors.green),
              _buildStatBox(context, 'Current Rank', '#${userProfile.rank}', Colors.purple),
            ],
          ),

          const SizedBox(height: 32),

          // Account Actions
          ElevatedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
