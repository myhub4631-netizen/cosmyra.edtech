import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../widgets/app_avatar.dart';
import '../../features/auth/login_screen.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final UserProfileModel? userProfile;
  final String activeExam;
  final VoidCallback? onOpenDrawer;
  final ValueChanged<String>? onSearch;

  const AppHeader({
    super.key,
    this.userProfile,
    this.activeExam = 'NEET',
    this.onOpenDrawer,
    this.onSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  late UserProfileModel _profile;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = widget.userProfile ?? _getEffectiveProfile();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userProfile != null && widget.userProfile != oldWidget.userProfile) {
      setState(() {
        _profile = widget.userProfile!;
      });
    }
  }

  Future<void> _loadProfile() async {
    final user = await SupabaseService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _profile = user;
      });
    }
  }

  UserProfileModel _getEffectiveProfile() {
    if (SupabaseService.activeUserSession != null) {
      return SupabaseService.activeUserSession!;
    }
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata ?? {};
      return UserProfileModel(
        id: user.id,
        email: user.email ?? 'user@cosmyra.edu',
        fullName: (meta['full_name'] ?? meta['name'] ?? user.email?.split('@').first ?? 'User').toString(),
        avatarUrl: (meta['avatar_url'] ?? meta['picture'] ?? meta['photo_url'])?.toString(),
        phoneNumber: (user.phone ?? meta['phone'] ?? meta['phone_number'])?.toString(),
        role: 'student',
        targetExam: 'NEET',
        targetYear: 2026,
      );
    }
    return SupabaseService.getMockProfile(role: 'student');
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationTile(
                '🔥 New NEET Master Test Series Live!',
                'Attempt full syllabus mock tests with real AIR ranking.',
                '10 mins ago',
                Icons.assignment_turned_in_rounded,
                const Color(0xFF4F46E5),
              ),
              const Divider(height: 16),
              _buildNotificationTile(
                '⚡ Study Streak Milestone!',
                'You reached a 12-day consecutive study streak!',
                '2 hours ago',
                Icons.local_fire_department_rounded,
                const Color(0xFFEA580C),
              ),
              const Divider(height: 16),
              _buildNotificationTile(
                '📚 NTA Practice Papers Updated',
                '2024 & 2025 NTA official questions are now available.',
                '1 day ago',
                Icons.menu_book_rounded,
                const Color(0xFF16A34A),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(String title, String subtitle, String time, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(time, style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
      ],
    );
  }

  void _showStreakInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('12 Day Study Streak!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Great job keeping up your preparation daily! Consistency is key to cracking ${widget.activeExam}.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFEA580C), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete 1 practice set today to maintain your streak to 13 days!',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF9A3412)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/practice');
            },
            child: const Text('Start Practice Now', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 992;

    final displayName = _profile.fullName.trim().isNotEmpty
        ? _profile.fullName.trim()
        : (_profile.email.contains('@') ? _profile.email.split('@').first : 'Mahboob User');

    final roleOrExamText = widget.activeExam.isNotEmpty
        ? '${widget.activeExam} ${_profile.targetYear}'
        : 'NEET 2027';

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // 1. Logo & Drawer Toggle Button
          Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Color(0xFF334155), size: 24),
                  tooltip: 'Open Menu Sidebar',
                  onPressed: () {
                    if (widget.onOpenDrawer != null) {
                      widget.onOpenDrawer!();
                    } else if (Scaffold.of(ctx).hasDrawer) {
                      Scaffold.of(ctx).openDrawer();
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => context.go('/dashboard'),
                child: Image.asset(
                  'assets/images/cosmyra_logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://neet-jee.in/assets/images/cosmyra_logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // 2. Search Bar (Visible on Tablet/Desktop, compact icon button on mobile)
          if (!isMobile)
            Expanded(
              child: Container(
                height: 42,
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: (query) {
                          if (widget.onSearch != null) {
                            widget.onSearch!(query);
                          } else {
                            context.go('/practice');
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search for questions, topics, tests...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Text('Ctrl /', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            )
          else
            const Spacer(),

          if (!isMobile) const SizedBox(width: 16),

          // 3. Store Badge Button
          InkWell(
            onTap: () => context.go('/test-series'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFE11D48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Store',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF08A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔥 SALE',
                      style: TextStyle(
                        color: Color(0xFF854D0E),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: isMobile ? 6 : 12),

          // 4. Streak Badge
          InkWell(
            onTap: () => _showStreakInfoDialog(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '12',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFEA580C)),
                      ),
                      if (!isMobile)
                        const Text(
                          'Day Streak',
                          style: TextStyle(fontSize: 8.5, color: Color(0xFFC2410C), fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: isMobile ? 6 : 12),

          // 5. Notification Bell Icon with Badge Count
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569), size: 22),
                tooltip: 'Notifications',
                onPressed: () => _showNotificationsDialog(context),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: isMobile ? 6 : 12),

          // 6. User Profile Avatar & Name Info
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppAvatar.fromProfile(_profile, size: 34),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleOrExamText,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(width: isMobile ? 6 : 12),

          // 7. Red Logout Button
          ElevatedButton.icon(
            onPressed: () async {
              await SupabaseService.logoutUserSession();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.white),
            label: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
