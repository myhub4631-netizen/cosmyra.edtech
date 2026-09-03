import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';
import '../../features/auth/login_screen.dart';

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;
  final VoidCallback? onOpenPractice;
  final VoidCallback? onOpenCustomPractice;
  final VoidCallback? onOpenCustomTest;
  final VoidCallback? onOpenPyqs;
  final VoidCallback? onOpenMistakes;
  final VoidCallback? onOpenMyTests;
  final VoidCallback? onOpenMockTests;
  final VoidCallback? onOpenTestSeries;
  final VoidCallback? onOpenLeaderboard;
  final VoidCallback? onLogout;

  const AppSidebar({
    super.key,
    this.selectedIndex = 0,
    this.onItemSelected,
    this.onOpenPractice,
    this.onOpenCustomPractice,
    this.onOpenCustomTest,
    this.onOpenPyqs,
    this.onOpenMistakes,
    this.onOpenMyTests,
    this.onOpenMockTests,
    this.onOpenTestSeries,
    this.onOpenLeaderboard,
    this.onLogout,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late int _activeIdx;

  @override
  void initState() {
    super.initState();
    _activeIdx = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      setState(() => _activeIdx = widget.selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'icon': Icons.storefront_rounded, 'label': 'Store', 'route': '/test-series', 'isStore': true},
      {'icon': Icons.track_changes_rounded, 'label': 'Practice', 'route': '/practice'},
      {'icon': Icons.edit_note_rounded, 'label': 'Custom Practice', 'route': '/custom-practice'},
      {'icon': Icons.assignment_outlined, 'label': 'Custom Test', 'route': '/custom-test'},
      {'icon': Icons.menu_book_rounded, 'label': 'PYQ', 'route': '/pyq'},
      {'icon': Icons.verified_user_outlined, 'label': 'NTA Questions', 'route': '/nta-practice'},
      {'icon': Icons.bookmark_border_rounded, 'label': 'Bookmarks', 'route': '/mistakes'},
      {'icon': Icons.cancel_outlined, 'label': 'My Mistakes', 'route': '/mistakes'},
      {'icon': Icons.assignment_turned_in_rounded, 'label': 'My All Tests', 'route': '/my-tests'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Test Series', 'route': '/test-series'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Analytics', 'route': '/analytics'},
      {'icon': Icons.emoji_events_outlined, 'label': 'Leaderboard', 'route': '/leaderboard'},
      {'icon': Icons.event_note_rounded, 'label': 'Study Plan', 'route': '/my-tests'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile', 'route': '/profile'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'route': '/profile'},
      {'icon': Icons.help_outline_rounded, 'label': 'Help & Support', 'route': '/help'},
      {'icon': Icons.logout_rounded, 'label': 'Logout', 'route': '/login'},
    ];

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header with Official Logo Image
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/cosmyra_logo.png',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.school_rounded, color: Color(0xFF0D7A53), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Cosmyra Neet Jee',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 2. Navigation Items List + Go Premium Card + Footer (all in smooth scrollable list)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  ...List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    final bool isStore = item['isStore'] == true;
                    final String label = item['label'] as String;
                    final IconData icon = item['icon'] as IconData;
                    final String route = item['route'] as String;
                    final bool isSelected = _activeIdx == index;

                    if (isStore) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () {
                            if (Scaffold.of(context).isDrawerOpen) {
                              Navigator.of(context).pop();
                            }
                            context.go('/test-series');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFE11D48)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Store',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF08A),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              '🔥 SALE',
                                              style: TextStyle(
                                                color: Color(0xFF854D0E),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Mock Tests & Packages',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: InkWell(
                        onTap: () async {
                          setState(() => _activeIdx = index);
                          if (widget.onItemSelected != null) {
                            widget.onItemSelected!(index);
                          }

                          // Close drawer if open
                          if (Scaffold.of(context).isDrawerOpen) {
                            Navigator.of(context).pop();
                          }

                          if (label == 'Logout') {
                            await SupabaseService.logoutUserSession();
                            if (widget.onLogout != null) widget.onLogout!();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                            return;
                          }

                          if (label == 'My All Tests') {
                            if (widget.onOpenMyTests != null) {
                              widget.onOpenMyTests!();
                            } else {
                              context.go('/my-tests');
                            }
                            return;
                          }

                          if (label == 'Practice') {
                            if (widget.onOpenPractice != null) {
                              widget.onOpenPractice!();
                            } else {
                              context.go('/custom-practice');
                            }
                            return;
                          }

                          if (label == 'Custom Practice') {
                            if (widget.onOpenCustomPractice != null) {
                              widget.onOpenCustomPractice!();
                            } else {
                              context.go('/custom-practice');
                            }
                            return;
                          }

                          if (label == 'Custom Test') {
                            if (widget.onOpenCustomTest != null) {
                              widget.onOpenCustomTest!();
                            } else {
                              context.go('/my-tests');
                            }
                            return;
                          }

                          if (label == 'PYQ' || label == 'NTA Questions') {
                            if (widget.onOpenPyqs != null) {
                              widget.onOpenPyqs!();
                            } else {
                              context.go('/pyq');
                            }
                            return;
                          }

                          if (label == 'Bookmarks' || label == 'My Mistakes') {
                            if (widget.onOpenMistakes != null) {
                              widget.onOpenMistakes!();
                            } else {
                              context.go('/mistakes');
                            }
                            return;
                          }

                          if (label == 'Test Series') {
                            if (widget.onOpenTestSeries != null) {
                              widget.onOpenTestSeries!();
                            } else {
                              context.go('/test-series');
                            }
                            return;
                          }

                          if (label == 'Leaderboard') {
                            if (widget.onOpenLeaderboard != null) {
                              widget.onOpenLeaderboard!();
                            } else {
                              context.go('/leaderboard');
                            }
                            return;
                          }

                          // Default navigation fallback
                          context.go(route);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 19,
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  label,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 14),

                  // 3. Go Premium Card (placed in scrollable list so it never overlaps or clips)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 15)),
                            const SizedBox(width: 8),
                            Text(
                              'Go Premium',
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unlock unlimited tests, detailed analytics, and exclusive features.',
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B), height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              if (Scaffold.of(context).isDrawerOpen) {
                                Navigator.of(context).pop();
                              }
                              context.go('/test-series');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Upgrade Now', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Small Footer Brand Logo
                  Center(
                    child: Opacity(
                      opacity: 0.75,
                      child: Image.asset(
                        'assets/images/cosmyra_logo.png',
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
