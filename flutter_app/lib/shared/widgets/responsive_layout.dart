import 'package:flutter/material.dart';
import '../../models/models.dart';

class ResponsiveLayoutShell extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final String activeExam;
  final ValueChanged<String> onExamChanged;
  final UserProfileModel userProfile;

  const ResponsiveLayoutShell({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.activeExam,
    required this.onExamChanged,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<ResponsiveLayoutShell> createState() => _ResponsiveLayoutShellState();
}

class _ResponsiveLayoutShellState extends State<ResponsiveLayoutShell> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Desktop Sidebar Navigation
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Logo / App Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cosmyra Neet Jee',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'ExamPrep • NEET & JEE',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Exam Selector Switcher
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: widget.activeExam,
                                isExpanded: true,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                items: const [
                                  DropdownMenuItem(value: 'NEET', child: Text('NEET UG Target')),
                                  DropdownMenuItem(value: 'JEE_MAIN', child: Text('JEE Main Target')),
                                  DropdownMenuItem(value: 'JEE_ADV', child: Text('JEE Advanced')),
                                ],
                                onChanged: (val) {
                                  if (val != null) widget.onExamChanged(val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Sidebar Nav Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildSidebarItem(0, Icons.dashboard_rounded, 'Dashboard'),
                        _buildSidebarItem(1, Icons.play_circle_fill_rounded, 'Practice Engine'),
                        _buildSidebarItem(2, Icons.assignment_rounded, 'Mock Tests'),
                        _buildSidebarItem(3, Icons.history_edu_rounded, 'PYQ & NTA Questions'),
                        _buildSidebarItem(4, Icons.auto_stories_rounded, 'Mistakes & Bookmarks'),
                        _buildSidebarItem(5, Icons.analytics_rounded, 'Analytics & Mastery'),
                        _buildSidebarItem(6, Icons.leaderboard_rounded, 'Leaderboard'),
                        _buildSidebarItem(7, Icons.person_rounded, 'My Profile'),
                        if (widget.userProfile.isAdmin) ...[
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                            child: Text('ADMINISTRATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          _buildSidebarItem(8, Icons.admin_panel_settings_rounded, 'Admin Dashboard'),
                          _buildSidebarItem(12, Icons.note_alt_rounded, 'Paper Predictions'),
                          _buildSidebarItem(9, Icons.sell_rounded, 'Pricing & Plans'),
                          _buildSidebarItem(10, Icons.account_tree_rounded, 'Exam Hierarchy'),
                          _buildSidebarItem(11, Icons.leaderboard_rounded, 'Admin Leaderboard'),
                        ],
                      ],
                    ),
                  ),

                  // User Info at Footer
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            widget.userProfile.fullName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userProfile.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.userProfile.role.toUpperCase(),
                                style: TextStyle(fontSize: 11, color: widget.userProfile.isAdmin ? Colors.redAccent : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(_getTitleForIndex(widget.selectedIndex)),
                  actions: [
                    IconButton(
                      icon: Icon(
                        widget.userProfile.role == 'admin' ? Icons.admin_panel_settings : Icons.person_outline,
                        color: widget.userProfile.role == 'admin' ? Colors.redAccent : null,
                      ),
                      tooltip: 'Toggle Demo Role (Student/Admin)',
                      onPressed: () {
                        final newRole = widget.userProfile.role == 'admin' ? 'student' : 'admin';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Switched view role to: $newRole')),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                body: widget.body,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile View with Bottom Navigation
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(_getTitleForIndex(widget.selectedIndex)),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.activeExam,
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      body: widget.body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex > 4 ? 4 : widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline_rounded), selectedIcon: Icon(Icons.play_circle_fill_rounded), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded), label: 'Tests'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard_rounded), label: 'Ranks'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = widget.selectedIndex == index;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => widget.onDestinationSelected(index),
      ),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home Dashboard';
      case 1:
        return 'Practice Engine';
      case 2:
        return 'Mock Tests & Exam Engine';
      case 3:
        return 'PYQ & NTA Questions';
      case 4:
        return 'Mistake Book & Bookmarks';
      case 5:
        return 'Analytics & Mastery';
      case 6:
        return 'Leaderboard Ranks';
      case 7:
        return 'User Profile & Settings';
      case 8:
        return 'Admin Dashboard Control';
      case 9:
        return 'Admin Pricing & Plans';
      case 10:
        return 'Exam & Content Hierarchy';
      case 11:
        return 'Admin Leaderboard';
      case 12:
        return 'Paper Predictions & Management';
      default:
        return 'Cosmyra Edu Platform';
    }
  }
}
