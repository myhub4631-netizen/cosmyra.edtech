import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({Key? key}) : super(key: key);

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _updates = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.fetchAppUpdates();
      if (mounted) {
        setState(() {
          _updates = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUpdates {
    return _updates.where((u) {
      final tag = (u['tag'] ?? '').toString().toLowerCase();
      final catMatch = _selectedCategory == 'All' ||
          tag.contains(_selectedCategory.toLowerCase()) ||
          (_selectedCategory == 'Releases' && (tag.contains('release') || u['isLatest'] == true));
      
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return catMatch;

      final title = (u['title'] ?? '').toString().toLowerCase();
      final version = (u['version'] ?? '').toString().toLowerCase();
      final highlights = (u['highlights'] as List? ?? []).join(' ').toLowerCase();

      final searchMatch = title.contains(q) || version.contains(q) || highlights.contains(q);
      return catMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.new_releases_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Cosmyra Updates',
              style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/test-series'),
            icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
            label: Text('Test Series', style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A), size: 20),
            onPressed: () {
              const url = 'https://neet-jee.in/updates';
              Clipboard.setData(const ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Updates page link copied to clipboard'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero Banner Header
              Container(
                width: double.infinity,
                color: const Color(0xFF0F172A),
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20, vertical: 36),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'OFFICIAL RELEASE LOG & CHANGELOG',
                                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'What\'s New in Cosmyra NEET & JEE',
                          style: GoogleFonts.inter(
                            fontSize: isDesktop ? 32 : 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track all platform enhancements, mobile layout optimizations, dynamic engine upgrades, and release notes in concise format.',
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8), height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        // Search & Filters Row
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              width: isDesktop ? 320 : double.infinity,
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (val) => setState(() => _searchQuery = val),
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Search updates, features...',
                                        hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCategoryFilterPill('All'),
                                  const SizedBox(width: 8),
                                  _buildCategoryFilterPill('Releases'),
                                  const SizedBox(width: 8),
                                  _buildCategoryFilterPill('Features'),
                                  const SizedBox(width: 8),
                                  _buildCategoryFilterPill('Design'),
                                  const SizedBox(width: 8),
                                  _buildCategoryFilterPill('Fixes'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Updates Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 28),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                          )
                        : _filteredUpdates.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 40, color: Color(0xFF64748B)),
                                    const SizedBox(height: 12),
                                    Text('No Updates Found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Try clearing your search or filter keywords.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredUpdates.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 20),
                                itemBuilder: (context, index) {
                                  final upd = _filteredUpdates[index];
                                  return _buildUpdateCard(upd);
                                },
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterPill(String catName) {
    final isSelected = _selectedCategory == catName;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = catName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155)),
        ),
        child: Text(
          catName,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> upd) {
    final version = (upd['version'] ?? 'v1.0.0').toString();
    final date = (upd['date'] ?? '').toString();
    final title = (upd['title'] ?? '').toString();
    final tag = (upd['tag'] ?? 'Update').toString();
    final isLatest = upd['isLatest'] == true;
    final highlights = (upd['highlights'] as List? ?? []).map((e) => e.toString()).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLatest ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0), width: isLatest ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isLatest ? 0.06 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isLatest ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    version,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                if (isLatest) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      'LATEST RELEASE',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                  ),
                ),
                const Spacer(),
                if (date.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), height: 1.25),
                ),
                const SizedBox(height: 14),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: highlights.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final hText = highlights[idx];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, size: 12, color: Color(0xFF059669)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hText,
                            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF334155), height: 1.45),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
