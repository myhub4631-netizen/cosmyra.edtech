import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/latex_view.dart';

class MistakesBookmarksScreen extends StatefulWidget {
  final Function(List<QuestionModel> questions) onStartPractice;

  const MistakesBookmarksScreen({Key? key, required this.onStartPractice}) : super(key: key);

  @override
  State<MistakesBookmarksScreen> createState() => _MistakesBookmarksScreenState();
}

class _MistakesBookmarksScreenState extends State<MistakesBookmarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MistakeModel> _mistakes = [];
  List<BookmarkModel> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final mistakes = await SupabaseService.getMistakes();
    final bookmarks = await SupabaseService.getBookmarks();
    setState(() {
      _mistakes = mistakes;
      _bookmarks = bookmarks;
      _isLoading = false;
    });
  }

  void _practiceMistakes() {
    final questions = _mistakes.where((m) => m.question != null).map((m) => m.question!).toList();
    if (questions.isNotEmpty) {
      widget.onStartPractice(questions);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No mistakes registered yet!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mistake Book & Saved Bookmarks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber_rounded), text: 'My Mistakes History'),
            Tab(icon: Icon(Icons.bookmark_outline_rounded), text: 'Saved Bookmarks'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Mistakes Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_mistakes.length} Questions in Mistake History', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Text('Auto-logged when answered incorrectly', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _practiceMistakes,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Practice My Mistakes'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _mistakes.isEmpty
                          ? const Center(child: Text('No mistakes logged yet! Great job.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _mistakes.length,
                              itemBuilder: (ctx, idx) {
                                final m = _mistakes[idx];
                                final q = m.question;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Chip(
                                              label: Text('Attempts: ${m.attemptCount}'),
                                              backgroundColor: Colors.red.withOpacity(0.1),
                                              side: BorderSide.none,
                                            ),
                                            Text(
                                              'Last attempted: ${m.lastAttemptedAt.day}/${m.lastAttemptedAt.month}/${m.lastAttemptedAt.year}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (q != null) LaTeXView(text: q.questionText),
                                        const SizedBox(height: 8),
                                        Text('Your last pick: ${m.lastSelectedAnswer}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // Bookmarks Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarks.length,
                  itemBuilder: (ctx, idx) {
                    final bm = _bookmarks[idx];
                    final q = bm.question;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.bookmark, color: Colors.amber),
                        title: q != null ? Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis) : const Text('Bookmark'),
                        subtitle: Text('Category: ${bm.category.toUpperCase()}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow_rounded),
                          onPressed: () {
                            if (q != null) widget.onStartPractice([q]);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
