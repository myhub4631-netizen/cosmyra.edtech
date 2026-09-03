import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/app_sidebar.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfileModel userProfile;
  final String activeExam;
  final ValueChanged<String> onExamChanged;
  final VoidCallback onSignOut;
  final Function(int tabIndex)? onNavigateTab;
  final VoidCallback? onOpenCustomPractice;
  final VoidCallback? onOpenCustomTest;
  final VoidCallback? onOpenPyqs;

  const ProfileScreen({
    Key? key,
    required this.userProfile,
    required this.activeExam,
    required this.onExamChanged,
    required this.onSignOut,
    this.onNavigateTab,
    this.onOpenCustomPractice,
    this.onOpenCustomTest,
    this.onOpenPyqs,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfileModel _currentProfile;
  late String _selectedExam;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.userProfile;
    _selectedExam = widget.activeExam.toUpperCase();
    _loadSavedProfileData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile != widget.userProfile) {
      setState(() {
        _currentProfile = widget.userProfile;
      });
    }
    if (oldWidget.activeExam != widget.activeExam) {
      setState(() {
        _selectedExam = widget.activeExam.toUpperCase();
      });
    }
  }

  Future<void> _loadSavedProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cosmyra_user_profile_data');
      if (str != null && str.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(str);
        if (mounted) {
          setState(() {
            _currentProfile = UserProfileModel.fromJson(json);
          });
        }
      }
    } catch (e) {
      debugPrint('Notice loading saved profile data: $e');
    }
  }

  Future<void> _saveProfileData(UserProfileModel updated) async {
    setState(() {
      _currentProfile = updated;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cosmyra_user_profile_data', jsonEncode(updated.toJson()));
      
      // Update Supabase DB in background
      await SupabaseService.client.from('profiles').update({
        'full_name': updated.fullName,
        'target_exam': updated.targetExam,
        'target_year': updated.targetYear,
        'class_level': updated.classLevel,
        'preferred_language': updated.preferredLanguage,
        'target_score': updated.targetScore,
        'target_rank': updated.targetRank,
        'subjects_focus': updated.subjectsFocus,
        'study_goal': updated.studyGoal,
        'city': updated.city,
        'state': updated.state,
      }).eq('id', updated.id);
    } catch (e) {
      debugPrint('Notice updating profile: $e');
    }
  }

  String get _selectedExamDisplay {
    if (_selectedExam == 'JEE_MAIN' || _selectedExam == 'JEE MAIN') return 'JEE Main';
    if (_selectedExam == 'JEE_ADV' || _selectedExam == 'JEE ADVANCED') return 'JEE Advanced';
    return 'NEET';
  }

  // Dynamic Exam-Specific Data Maps
  Map<String, String> get _examAcademicDetails {
    if (_selectedExamDisplay == 'JEE Main') {
      return {
        'Exam': 'JEE Main',
        'Target Year': '${_currentProfile.targetYear}',
        'Class': _currentProfile.classLevel,
        'Preferred Language': _currentProfile.preferredLanguage,
        'Target Score': '250+',
        'Target Rank': 'Top 5,000',
        'Subjects Focus': 'PCM',
        'Study Goal': 'NIT Trichy / Surathkal CSE',
      };
    } else if (_selectedExamDisplay == 'JEE Advanced') {
      return {
        'Exam': 'JEE Advanced',
        'Target Year': '${_currentProfile.targetYear}',
        'Class': _currentProfile.classLevel,
        'Preferred Language': _currentProfile.preferredLanguage,
        'Target Score': '210+',
        'Target Rank': 'Top 2,000',
        'Subjects Focus': 'PCM',
        'Study Goal': 'IIT Bombay Computer Science',
      };
    }
    return {
      'Exam': 'NEET',
      'Target Year': '${_currentProfile.targetYear}',
      'Class': _currentProfile.classLevel,
      'Preferred Language': _currentProfile.preferredLanguage,
      'Target Score': _currentProfile.targetScore,
      'Target Rank': _currentProfile.targetRank,
      'Subjects Focus': _currentProfile.subjectsFocus,
      'Study Goal': _currentProfile.studyGoal,
    };
  }

  Map<String, String> get _examRankStats {
    if (_selectedExamDisplay == 'JEE Main') {
      return {
        'currentAir': '4,210',
        'airRange': '3K – 5K',
        'percentile': '98.24%',
        'previousAir': '6,150',
        'improvement': '1,940',
      };
    } else if (_selectedExamDisplay == 'JEE Advanced') {
      return {
        'currentAir': '1,840',
        'airRange': '1.5K – 2.5K',
        'percentile': '99.12%',
        'previousAir': '2,950',
        'improvement': '1,110',
      };
    }
    return {
      'currentAir': '12,845',
      'airRange': '10K – 15K',
      'percentile': '93.42%',
      'previousAir': '15,230',
      'improvement': '2,385',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: Drawer(
        child: AppSidebar(
          selectedIndex: 7,
          onOpenPractice: widget.onOpenCustomPractice,
          onOpenCustomPractice: widget.onOpenCustomPractice,
          onOpenCustomTest: widget.onOpenCustomTest,
          onOpenPyqs: widget.onOpenPyqs,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HEADER BAR
                  _buildHeaderBar(context),

                  const SizedBox(height: 16),

                  // 2. PROFILE CARD
                  _buildProfileCard(),

                  const SizedBox(height: 16),

                  // 3. EXAM SWITCHER SEGMENTED CONTROL
                  _buildExamSwitcher(),

                  const SizedBox(height: 16),

                  // 4. ACADEMIC PROFILE CARD
                  _buildAcademicProfileCard(),

                  const SizedBox(height: 16),

                  // 5. PERFORMANCE SNAPSHOT CARD
                  _buildPerformanceSnapshotCard(),

                  const SizedBox(height: 16),

                  // 6. RANK & PERFORMANCE + ACHIEVEMENTS ROW
                  _buildRankAndAchievementsRow(),

                  const SizedBox(height: 16),

                  // 7. STUDY ACTIVITY CARD
                  _buildStudyActivityCard(),

                  const SizedBox(height: 16),

                  // 7.5. MY PURCHASES & SUBSCRIPTIONS SECTION
                  _buildMyPurchasesSection(),

                  const SizedBox(height: 16),

                  // 8. QUICK ACTIONS SECTION
                  _buildQuickActionsSection(),

                  const SizedBox(height: 16),

                  // 9. MOTIVATIONAL CTA CARD
                  _buildMotivationalCtaCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. HEADER BAR
  Widget _buildHeaderBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (ctx) => InkWell(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(6.0),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.menu_rounded, size: 20, color: Color(0xFF0F172A)),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                Text(
                  'Your progress, performance & goals',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications: 3 new test updates available')),
                    );
                  },
                  icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF0F172A)),
                  tooltip: 'Notifications',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _showSettingsModal(context),
              icon: const Icon(Icons.settings_outlined, size: 24, color: Color(0xFF0F172A)),
              tooltip: 'Settings',
            ),
          ],
        ),
      ],
    );
  }

  // 2. PROFILE CARD
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with camera button overlay
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)]),
                      boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: Text(
                        _currentProfile.fullName.isNotEmpty ? _currentProfile.fullName[0].toUpperCase() : 'M',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: () => _showEditProfileBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Student identity info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _currentProfile.fullName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF3B82F6)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$_selectedExamDisplay ${_currentProfile.targetYear} Aspirant',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 4),
                        const Text('🎯', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 2),
                        Text(
                          '${_currentProfile.city}, ${_currentProfile.state}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit Profile Button
              OutlinedButton.icon(
                onPressed: () => _showEditProfileBottomSheet(context),
                icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4F46E5)),
                label: const Text('Edit Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Profile completion progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Profile 85% complete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  Text('85%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 0.85,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEF2FF),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. EXAM SWITCHER SEGMENTED CONTROL
  Widget _buildExamSwitcher() {
    final List<Map<String, dynamic>> exams = [
      {'key': 'NEET', 'label': 'NEET', 'icon': Icons.medical_services_outlined},
      {'key': 'JEE_MAIN', 'label': 'JEE Main', 'icon': Icons.account_balance_outlined},
      {'key': 'JEE_ADV', 'label': 'JEE Advanced', 'icon': Icons.science_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: exams.map((exam) {
          final isSelected = (_selectedExam == exam['key']) ||
              (_selectedExam == 'NEET' && exam['key'] == 'NEET') ||
              (_selectedExam.contains('MAIN') && exam['key'] == 'JEE_MAIN') ||
              (_selectedExam.contains('ADV') && exam['key'] == 'JEE_ADV');

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedExam = exam['key'];
                });
                widget.onExamChanged(exam['key']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(exam['icon'], size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      exam['label'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. ACADEMIC PROFILE CARD
  Widget _buildAcademicProfileCard() {
    final details = _examAcademicDetails;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.school_outlined, size: 20, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text('Academic Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
              InkWell(
                onTap: () => _showEditProfileBottomSheet(context),
                child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              ),
            ],
          ),

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final crossCount = isMobile ? 2 : 4;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: details.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  childAspectRatio: isMobile ? 2.4 : 2.2,
                ),
                itemBuilder: (ctx, index) {
                  final entry = details.entries.elementAt(index);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text(
                        entry.value,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. PERFORMANCE SNAPSHOT CARD
  Widget _buildPerformanceSnapshotCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text('Performance Snapshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
              InkWell(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(5); // Analytics tab
                  }
                },
                child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              ),
            ],
          ),

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              final List<Map<String, dynamic>> stats = [
                {'icon': Icons.description_outlined, 'value': '42', 'label': 'Tests Attempted', 'bg': const Color(0xFFEEF2FF), 'iconColor': const Color(0xFF4F46E5)},
                {'icon': Icons.menu_book_rounded, 'value': '${_currentProfile.questionsAttempted}', 'label': 'Questions Solved', 'bg': const Color(0xFFEFF6FF), 'iconColor': const Color(0xFF2563EB)},
                {'icon': Icons.track_changes_rounded, 'value': '${_currentProfile.accuracy.toInt()}%', 'label': 'Accuracy', 'bg': const Color(0xFFDCFCE7), 'iconColor': const Color(0xFF16A34A)},
                {'icon': Icons.local_fire_department_rounded, 'value': '${_currentProfile.studyStreak} Days', 'label': 'Current Streak', 'bg': const Color(0xFFFFFBEB), 'iconColor': const Color(0xFFEA580C)},
              ];

              if (isMobile) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (ctx, idx) => _buildStatTile(stats[idx]),
                );
              }

              return Row(
                children: stats.map((st) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: _buildStatTile(st)))).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(Map<String, dynamic> st) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (st['bg'] as Color).withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (st['bg'] as Color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(st['icon'] as IconData, size: 22, color: st['iconColor'] as Color),
          const SizedBox(height: 8),
          Text(st['value'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(st['label'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 6. RANK & PERFORMANCE + ACHIEVEMENTS ROW
  Widget _buildRankAndAchievementsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return Column(
            children: [
              _buildRankCard(),
              const SizedBox(height: 16),
              _buildAchievementsCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildRankCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildAchievementsCard()),
          ],
        );
      },
    );
  }

  // 6A. RANK & PERFORMANCE CARD
  Widget _buildRankCard() {
    final rankStats = _examRankStats;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.show_chart_rounded, size: 20, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text('Rank & Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
              InkWell(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(0); // Open AIR tracker / Dashboard
                  }
                },
                child: const Text('View AIR Tracker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current AIR', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(rankStats['currentAir']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AIR Range', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(rankStats['airRange']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Percentile', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(rankStats['percentile']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Previous AIR', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(rankStats['previousAir']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 2),
                  Text(rankStats['improvement']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                  const SizedBox(width: 4),
                  const Text('Improvement', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
              SizedBox(
                width: 80,
                height: 24,
                child: CustomPaint(
                  painter: SparklinePainter(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6B. ACHIEVEMENTS CARD
  Widget _buildAchievementsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.emoji_events_outlined, size: 20, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text('Achievements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
              InkWell(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(6); // Leaderboard tab
                  }
                },
                child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hexagonal Badge Icons Row
          Row(
            children: [
              _buildBadgeHex('🔥 7', const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              _buildBadgeHex('🎯', const Color(0xFF059669)),
              const SizedBox(width: 8),
              _buildBadgeHex('🛡️', const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('+8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Streak', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  Text('${_currentProfile.studyStreak} Days', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Total Points', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  SizedBox(height: 2),
                  Text('2,450 ⭐', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leaderboard Rank', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  Text('#${_currentProfile.rank}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(20)),
                child: const Text('Top 5%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeHex(String text, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
    );
  }

  // 7. STUDY ACTIVITY CARD
  Widget _buildStudyActivityCard() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month_outlined, size: 20, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text('Study Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Heatmap matrix
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: days.map((day) {
                    return Column(
                      children: [
                        Text(day, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        // 3 vertical dots per day
                        ...List.generate(3, (idx) {
                          final isSun = day == 'Sun';
                          final isLight = isSun && idx > 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 3),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF10B981),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),

              Container(height: 60, width: 1, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 16)),

              // Stats Box right
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.menu_book_outlined, size: 14, color: Color(0xFF4F46E5)),
                          SizedBox(width: 4),
                          Text('18', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                      const Text('Questions today', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFEA580C)),
                          SizedBox(width: 4),
                          Text('7', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                      const Text('Day streak', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Progress Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: 0.82,
                          strokeWidth: 5,
                          backgroundColor: Color(0xFFEEF2FF),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('82%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          Text('This week', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7.5 MY PURCHASES & SUBSCRIPTIONS SECTION
  Widget _buildMyPurchasesSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.fetchUserEntitlements(_currentProfile.id),
      builder: (context, snapshot) {
        final entitlements = snapshot.data ?? [];
        final hasPurchases = entitlements.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Purchases & Subscriptions',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        hasPurchases ? '${entitlements.length} Active test series and suites enrolled' : 'Manage your subscribed packages & test suites',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.go('/test-series'),
                    icon: const Icon(Icons.storefront_outlined, size: 15, color: Color(0xFF4F46E5)),
                    label: const Text('Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!hasPurchases) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.quiz_outlined, color: Color(0xFF4F46E5), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Active Test Series Yet',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Enroll in NTA-standard NEET & JEE test series with instant CBT access.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => context.go('/test-series'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Browse', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entitlements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final ent = entitlements[idx];
                    final title = ent['product_title']?.toString() ?? 'Test Series';
                    final validUntil = ent['valid_until']?.toString() ?? '';
                    final validDateStr = validUntil.length >= 10 ? validUntil.substring(0, 10) : 'Active';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('ACTIVE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Valid until $validDateStr • Full CBT Access',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => context.go('/test-series'),
                            icon: const Icon(Icons.play_arrow_rounded, size: 14),
                            label: const Text('Continue', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 8. QUICK ACTIONS SECTION
  Widget _buildQuickActionsSection() {
    final actions = [
      {'icon': Icons.bar_chart_rounded, 'label': 'My Performance', 'tab': 5, 'iconBg': const Color(0xFFEEF2FF), 'iconColor': const Color(0xFF4F46E5)},
      {'icon': Icons.emoji_events_outlined, 'label': 'Leaderboard', 'tab': 6, 'iconBg': const Color(0xFFFFFBEB), 'iconColor': const Color(0xFFD97706)},
      {'icon': Icons.track_changes_rounded, 'label': 'AIR Tracker', 'tab': 0, 'iconBg': const Color(0xFFEFF6FF), 'iconColor': const Color(0xFF2563EB)},
      {'icon': Icons.history_rounded, 'label': 'Practice History', 'route': '/my-tests', 'iconBg': const Color(0xFFDCFCE7), 'iconColor': const Color(0xFF16A34A)},
      {'icon': Icons.bookmark_border_rounded, 'label': 'Saved Questions', 'route': '/saved', 'iconBg': const Color(0xFFF3E8FF), 'iconColor': const Color(0xFF8B5CF6)},
      {'icon': Icons.pie_chart_outline_rounded, 'label': 'Study Statistics', 'tab': 5, 'iconBg': const Color(0xFFE0F2FE), 'iconColor': const Color(0xFF0284C7)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),

          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (ctx, idx) {
              final act = actions[idx];
              return InkWell(
                onTap: () {
                  if (act.containsKey('tab') && widget.onNavigateTab != null) {
                    widget.onNavigateTab!(act['tab'] as int);
                  } else if (act['label'] == 'Practice History') {
                    if (widget.onOpenCustomPractice != null) {
                      widget.onOpenCustomPractice!();
                    } else if (widget.onNavigateTab != null) {
                      widget.onNavigateTab!(2);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening ${act['label']}...')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: act['iconBg'] as Color, borderRadius: BorderRadius.circular(8)),
                        child: Icon(act['icon'] as IconData, size: 16, color: act['iconColor'] as Color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          act['label'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 9. MOTIVATIONAL CTA CARD
  Widget _buildMotivationalCtaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          const Text('🚀', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Keep Practicing, Keep Improving! 🚀',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  '"Consistency today, success tomorrow."',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onOpenCustomPractice != null) {
                widget.onOpenCustomPractice!();
              } else if (widget.onNavigateTab != null) {
                widget.onNavigateTab!(2); // Practice tab
              }
            },
            icon: const Text('Start Practicing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            label: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // SETTINGS MODAL
  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Color(0xFF4F46E5)),
                title: const Text('Edit Account Info'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditProfileBottomSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Color(0xFF4F46E5)),
                title: const Text('Security & Password'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent to your email')));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Sign Out Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onSignOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // EDIT PROFILE BOTTOM SHEET
  void _showEditProfileBottomSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _currentProfile.fullName);
    final cityCtrl = TextEditingController(text: _currentProfile.city);
    final stateCtrl = TextEditingController(text: _currentProfile.state);
    final goalCtrl = TextEditingController(text: _currentProfile.studyGoal);
    final targetScoreCtrl = TextEditingController(text: _currentProfile.targetScore);
    String selectedClass = _currentProfile.classLevel;
    String selectedLang = _currentProfile.preferredLanguage;
    int selectedYear = _currentProfile.targetYear;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit Profile & Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stateCtrl,
                            decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(labelText: 'Class / Student Status', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Dropper', child: Text('Dropper / Repeater')),
                        DropdownMenuItem(value: 'Class 12', child: Text('Class 12 Student')),
                        DropdownMenuItem(value: 'Class 11', child: Text('Class 11 Student')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedClass = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedLang,
                      decoration: const InputDecoration(labelText: 'Preferred Language', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'English', child: Text('English Medium')),
                        DropdownMenuItem(value: 'Hindi', child: Text('Hindi Medium')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedLang = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: targetScoreCtrl,
                            decoration: const InputDecoration(labelText: 'Target Score', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedYear,
                            decoration: const InputDecoration(labelText: 'Target Year', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 2025, child: Text('2025')),
                              DropdownMenuItem(value: 2026, child: Text('2026')),
                              DropdownMenuItem(value: 2027, child: Text('2027')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedYear = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: goalCtrl,
                      decoration: const InputDecoration(labelText: 'Dream Career / Study Goal', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final updated = _currentProfile.copyWith(
                            fullName: nameCtrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            state: stateCtrl.text.trim(),
                            classLevel: selectedClass,
                            preferredLanguage: selectedLang,
                            targetScore: targetScoreCtrl.text.trim(),
                            targetYear: selectedYear,
                            studyGoal: goalCtrl.text.trim(),
                          );
                          _saveProfileData(updated);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated successfully!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Profile Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Sparkline Painter for AIR Rank Trend Graph
class SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF10B981).withOpacity(0.25), const Color(0xFF10B981).withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
      size.width * 0.25, size.height * 0.9,
      size.width * 0.5, size.height * 0.3,
      size.width * 0.75, size.height * 0.4,
    );
    path.lineTo(size.width, size.height * 0.1);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // End point indicator dot
    canvas.drawCircle(Offset(size.width, size.height * 0.1), 3.5, Paint()..color = const Color(0xFF10B981));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
