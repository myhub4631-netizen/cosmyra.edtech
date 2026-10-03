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
    final sections = [
      {
        'header': 'STORE & PACKAGES',
        'items': [
          {'index': 0, 'icon': Icons.storefront_rounded, 'label': 'Store & Packages', 'route': '/test-series', 'isStore': true},
        ]
      },
      {
        'header': 'PRACTICE ENGINE',
        'items': [
          {'index': 1, 'icon': Icons.track_changes_rounded, 'label': 'Practice', 'route': '/practice'},
          {'index': 2, 'icon': Icons.tune_rounded, 'label': 'Custom Practice', 'route': '/custom-practice'},
          {'index': 3, 'icon': Icons.assignment_outlined, 'label': 'Custom Test Wizard', 'route': '/custom-test'},
          {'index': 4, 'icon': Icons.menu_book_rounded, 'label': '15-Yr PYQ Bank', 'route': '/pyq'},
          {'index': 5, 'icon': Icons.verified_rounded, 'label': 'NTA Question Bank', 'route': '/nta-practice'},
        ]
      },
      {
        'header': 'TESTS & ANALYTICS',
        'items': [
          {'index': 6, 'icon': Icons.bookmark_border_rounded, 'label': 'Bookmarks', 'route': '/mistakes'},
          {'index': 7, 'icon': Icons.error_outline_rounded, 'label': 'My Mistakes Radar', 'route': '/mistakes'},
          {'index': 8, 'icon': Icons.assignment_turned_in_rounded, 'label': 'My All Tests', 'route': '/my-tests'},
          {'index': 9, 'icon': Icons.dashboard_customize_rounded, 'label': 'Test Series Catalog', 'route': '/test-series'},
          {'index': 10, 'icon': Icons.insights_rounded, 'label': 'Performance Analytics', 'route': '/analytics'},
          {'index': 11, 'icon': Icons.emoji_events_rounded, 'label': 'AIR Leaderboards', 'route': '/leaderboard'},
        ]
      },
      {
        'header': 'ACCOUNT & SUPPORT',
        'items': [
          {'index': 12, 'icon': Icons.event_note_rounded, 'label': 'Study Schedule', 'route': '/my-tests'},
          {'index': 13, 'icon': Icons.person_rounded, 'label': 'My Profile', 'route': '/profile'},
          {'index': 14, 'icon': Icons.settings_rounded, 'label': 'Settings', 'route': '/profile'},
          {'index': 15, 'icon': Icons.help_outline_rounded, 'label': 'Help & Support', 'route': '/help'},
          {'index': 16, 'icon': Icons.logout_rounded, 'label': 'Logout', 'route': '/login', 'isLogout': true},
        ]
      },
    ];

    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(2, 0)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header with Official Brand Emblem
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: InkWell(
                onTap: () => context.go('/dashboard'),
                child: Image.asset(
                  'assets/images/cosmyra_logo.png',
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cosmyra NEET | JEE', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            Text('Practice • Analyze • Succeed', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 2. Navigation Items List grouped cleanly
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                itemCount: sections.length,
                itemBuilder: (context, sIdx) {
                  final section = sections[sIdx];
                  final header = section['header'] as String;
                  final items = section['items'] as List<Map<String, dynamic>>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sIdx > 0) const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 6, top: 4),
                        child: Text(
                          header,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      ...items.map((item) {
                        final int index = item['index'] as int;
                        final bool isStore = item['isStore'] == true;
                        final bool isLogout = item['isLogout'] == true;
                        final String label = item['label'] as String;
                        final IconData icon = item['icon'] as IconData;
                        final String route = item['route'] as String;
                        final bool isSelected = _activeIdx == index;

                        if (isStore) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                if (Scaffold.of(context).isDrawerOpen) {
                                  Navigator.of(context).pop();
                                }
                                context.go('/test-series');
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x3D4F46E5), blurRadius: 12, offset: Offset(0, 4)),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(10),
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
                                                'Store & Packages',
                                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF08A),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text('🔥 SALE', style: TextStyle(color: Color(0xFF854D0E), fontSize: 8.5, fontWeight: FontWeight.w900)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text('Mock Tests & Passes', style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white70),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                setState(() => _activeIdx = index);
                                if (widget.onItemSelected != null) widget.onItemSelected!(index);
                                if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();

                                if (isLogout) {
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

                                if (label == 'Practice' && widget.onOpenPractice != null) {
                                  widget.onOpenPractice!();
                                } else if (label.contains('Custom Practice') && widget.onOpenCustomPractice != null) {
                                  widget.onOpenCustomPractice!();
                                } else if (label.contains('Custom Test') && widget.onOpenCustomTest != null) {
                                  widget.onOpenCustomTest!();
                                } else if (label.contains('PYQ') && widget.onOpenPyqs != null) {
                                  widget.onOpenPyqs!();
                                } else if (label.contains('Mistakes') && widget.onOpenMistakes != null) {
                                  widget.onOpenMistakes!();
                                } else if (label.contains('My All Tests') && widget.onOpenMyTests != null) {
                                  widget.onOpenMyTests!();
                                } else if (label.contains('Test Series') && widget.onOpenTestSeries != null) {
                                  widget.onOpenTestSeries!();
                                } else if (label.contains('Leaderboard') && widget.onOpenLeaderboard != null) {
                                  widget.onOpenLeaderboard!();
                                } else {
                                  context.go(route);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)])
                                      : null,
                                  color: isSelected ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [const BoxShadow(color: Color(0x334F46E5), blurRadius: 8, offset: Offset(0, 3))]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      icon,
                                      size: 19,
                                      color: isSelected
                                          ? Colors.white
                                          : (isLogout ? const Color(0xFFEF4444) : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : (isLogout ? const Color(0xFFEF4444) : const Color(0xFF334155)),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            // 3. Bottom Go Premium Card Banner
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x20312E81), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('Go Premium', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Unlock 500+ mock tests, video solutions & AI error radar.', style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFC7D2FE))),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/pricing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('Upgrade Now →', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
