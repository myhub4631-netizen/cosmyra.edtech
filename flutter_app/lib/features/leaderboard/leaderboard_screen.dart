import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const LeaderboardScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntryModel> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaderboard('daily');
  }

  Future<void> _loadLeaderboard(String period) async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getLeaderboard(period: period);
    setState(() {
      _entries = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competitive Exam Leaderboards'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (idx) {
            final period = idx == 0 ? 'daily' : (idx == 1 ? 'weekly' : 'monthly');
            _loadLeaderboard(period);
          },
          tabs: const [
            Tab(text: 'Daily Ranks'),
            Tab(text: 'Weekly Ranks'),
            Tab(text: 'Monthly Ranks'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top 3 Podium Card
                if (_entries.length >= 3)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    color: Theme.of(context).cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildPodiumAvatar(_entries[1], 2, Colors.blueGrey, 70), // Rank 2
                        _buildPodiumAvatar(_entries[0], 1, Colors.amber, 90),     // Rank 1
                        _buildPodiumAvatar(_entries[2], 3, Colors.orangeAccent, 60), // Rank 3
                      ],
                    ),
                  ),

                const Divider(height: 1),

                // Anti-gaming Info Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Theme.of(context).primaryColor.withOpacity(0.06),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fair Anti-Cheat Scoring: Calculated based on Correct Answers + Accuracy Bonus + Test Performance.',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // Leaderboard List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (ctx, idx) {
                      final entry = _entries[idx];
                      final isMe = entry.userId == widget.userProfile.id || entry.rank == widget.userProfile.rank;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isMe ? Theme.of(context).primaryColor.withOpacity(0.12) : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: entry.rank == 1
                                ? Colors.amber
                                : (entry.rank == 2 ? Colors.grey : (entry.rank == 3 ? Colors.orangeAccent : Theme.of(context).dividerColor.withOpacity(0.2))),
                            child: Text(
                              '#${entry.rank}',
                              style: TextStyle(
                                color: entry.rank <= 3 ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(entry.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (isMe)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Text('Accuracy: ${entry.accuracy}% • ${entry.questionsAttempted} Solved'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${entry.score.toInt()} pts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                              Text('🔥 ${entry.streakDays}d streak', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPodiumAvatar(LeaderboardEntryModel entry, int rank, Color color, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: rank == 1 ? 32 : 26,
          backgroundColor: color,
          child: Text(
            entry.fullName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(entry.fullName.split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text('${entry.score.toInt()} pts', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text('#$rank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
      ],
    );
  }
}
