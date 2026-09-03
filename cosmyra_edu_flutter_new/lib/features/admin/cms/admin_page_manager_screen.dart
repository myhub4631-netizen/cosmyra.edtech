import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../core/services/supabase_service.dart';
import 'admin_page_editor_screen.dart';

class AdminPageManagerScreen extends StatefulWidget {
  final UserProfileModel? userProfile;

  const AdminPageManagerScreen({super.key, this.userProfile});

  @override
  State<AdminPageManagerScreen> createState() => _AdminPageManagerScreenState();
}

class _AdminPageManagerScreenState extends State<AdminPageManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all'; // 'all', 'published', 'draft'
  bool _isLoading = true;
  List<CmsPageModel> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPages() async {
    setState(() => _isLoading = true);
    final results = await SupabaseService.fetchCmsPages(
      search: _searchController.text.trim(),
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );
    if (mounted) {
      setState(() {
        _pages = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePublish(CmsPageModel page) async {
    final nextStatus = !page.isPublished;
    final success = await SupabaseService.toggleCmsPagePublish(page.id, nextStatus);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextStatus ? 'Page published live!' : 'Page unpublished to draft.'),
            backgroundColor: nextStatus ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
        );
        _loadPages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.'), backgroundColor: Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _duplicatePage(CmsPageModel page) async {
    setState(() => _isLoading = true);
    final duplicate = await SupabaseService.duplicateCmsPage(page);
    if (mounted) {
      if (duplicate != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicated "${page.title}" as draft.'),
            backgroundColor: const Color(0xFF4F46E5),
          ),
        );
        _loadPages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to duplicate page.'), backgroundColor: Color(0xFFDC2626)),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(CmsPageModel page) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 10),
            Text('Delete Page?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${page.title}"?\n\nSlug: /pages/${page.slug}\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final ok = await SupabaseService.deleteCmsPage(page.id);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Page deleted successfully.'), backgroundColor: Color(0xFF10B981)),
          );
          _loadPages();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete page.'), backgroundColor: Color(0xFFDC2626)),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/admin');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article_outlined, color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Page Manager (CMS)',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (ctx) => const AdminPageEditorScreen()),
              );
              if (created == true) _loadPages();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create New Page', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top control bar (Search & Filter)
                _buildFilterBar(isDesktop),
                const SizedBox(height: 18),

                // Table / Card List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _pages.isEmpty
                          ? _buildEmptyState()
                          : _buildPagesList(isDesktop),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadPages(),
                    decoration: InputDecoration(
                      hintText: 'Search by page title or URL slug...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadPages();
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildStatusSegment(),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Refresh List',
                  onPressed: _loadPages,
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadPages(),
                  decoration: InputDecoration(
                    hintText: 'Search pages...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatusSegment()),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loadPages,
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatusSegment() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'all', label: Text('All')),
        ButtonSegment(value: 'published', label: Text('Published')),
        ButtonSegment(value: 'draft', label: Text('Drafts')),
      ],
      selected: {_selectedStatus},
      onSelectionChanged: (set) {
        setState(() => _selectedStatus = set.first);
        _loadPages();
      },
      style: ButtonStyle(
        textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.find_in_page_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'No Pages Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No pages match your search query "${_searchController.text}".'
                  : 'Start by creating your first dynamic content page.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (ctx) => const AdminPageEditorScreen()),
                );
                if (created == true) _loadPages();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create New Page'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagesList(bool isDesktop) {
    return ListView.separated(
      itemCount: _pages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final page = _pages[index];
        return _buildPageCard(page, isDesktop);
      },
    );
  }

  Widget _buildPageCard(CmsPageModel page, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: page.isPublished ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: page.isPublished ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
              ),
            ),
            child: Icon(
              page.isSystem ? Icons.verified_outlined : Icons.description_outlined,
              color: page.isPublished ? const Color(0xFF059669) : const Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        page.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(page.status),
                    if (page.isSystem) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('System', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '/pages/${page.slug}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Updated: ${_formatDate(page.updatedAt)}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview button
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Preview Page',
                onPressed: () => context.push('/pages/${page.slug}'),
              ),
              // Publish / Unpublish Toggle
              IconButton(
                icon: Icon(
                  page.isPublished ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                  size: 20,
                  color: page.isPublished ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                ),
                tooltip: page.isPublished ? 'Unpublish to Draft' : 'Publish Live',
                onPressed: () => _togglePublish(page),
              ),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF4F46E5)),
                tooltip: 'Edit Page',
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (ctx) => AdminPageEditorScreen(pageToEdit: page)),
                  );
                  if (updated == true) _loadPages();
                },
              ),
              // More actions (Duplicate, Delete)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF64748B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val == 'duplicate') _duplicatePage(page);
                  if (val == 'delete') _confirmDelete(page);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 16, color: Color(0xFF4F46E5)),
                        SizedBox(width: 8),
                        Text('Duplicate Page', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                        SizedBox(width: 8),
                        Text('Delete Page', style: TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isPub = status == 'published';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPub ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPub ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isPub ? const Color(0xFF15803D) : const Color(0xFFB45309),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
