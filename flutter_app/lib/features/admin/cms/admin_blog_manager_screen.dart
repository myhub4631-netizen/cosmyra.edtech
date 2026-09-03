import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../core/services/supabase_service.dart';
import 'admin_blog_editor_screen.dart';

class AdminBlogManagerScreen extends StatefulWidget {
  final UserProfileModel? userProfile;

  const AdminBlogManagerScreen({super.key, this.userProfile});

  @override
  State<AdminBlogManagerScreen> createState() => _AdminBlogManagerScreenState();
}

class _AdminBlogManagerScreenState extends State<AdminBlogManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all'; // 'all', 'published', 'draft'
  String _selectedCategory = 'all';

  bool _isLoading = true;
  List<CmsBlogPostModel> _posts = [];
  List<CmsBlogCategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final cats = await SupabaseService.fetchBlogCategories();
    final results = await SupabaseService.fetchBlogPosts(
      search: _searchController.text.trim(),
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
    );

    if (mounted) {
      setState(() {
        _categories = cats;
        _posts = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final results = await SupabaseService.fetchBlogPosts(
      search: _searchController.text.trim(),
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _posts = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePublish(CmsBlogPostModel post) async {
    final nextStatus = !post.isPublished;
    final success = await SupabaseService.toggleBlogPostPublish(post.id, nextStatus);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextStatus ? 'Blog post published live!' : 'Post unpublished to draft.'),
            backgroundColor: nextStatus ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
        );
        _loadPosts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.'), backgroundColor: Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _duplicatePost(CmsBlogPostModel post) async {
    setState(() => _isLoading = true);
    final duplicate = await SupabaseService.duplicateBlogPost(post);
    if (mounted) {
      if (duplicate != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicated "${post.title}" as draft.'),
            backgroundColor: const Color(0xFF4F46E5),
          ),
        );
        _loadPosts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to duplicate post.'), backgroundColor: Color(0xFFDC2626)),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(CmsBlogPostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 10),
            Text('Delete Blog Post?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${post.title}"?\n\nSlug: /blog/${post.slug}\n\nThis action cannot be undone.',
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
      final ok = await SupabaseService.deleteBlogPost(post.id);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blog post deleted successfully.'), backgroundColor: Color(0xFF10B981)),
          );
          _loadPosts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete post.'), backgroundColor: Color(0xFFDC2626)),
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
              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Blog Manager (CMS)',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (ctx) => AdminBlogEditorScreen(categories: _categories)),
              );
              if (created == true) _loadPosts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Blog Post', style: TextStyle(fontWeight: FontWeight.bold)),
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
                _buildFilterBar(isDesktop),
                const SizedBox(height: 18),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _posts.isEmpty
                          ? _buildEmptyState()
                          : _buildPostsList(isDesktop),
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
                    onSubmitted: (_) => _loadPosts(),
                    decoration: InputDecoration(
                      hintText: 'Search by article title or slug...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadPosts();
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildCategoryDropdown(),
                const SizedBox(width: 16),
                _buildStatusSegment(),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loadPosts,
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadPosts(),
                  decoration: InputDecoration(
                    hintText: 'Search blog posts...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCategoryDropdown()),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loadPosts,
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatusSegment(),
              ],
            ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isDense: true,
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Categories', style: TextStyle(fontSize: 13))),
            ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 13)))),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCategory = val);
              _loadPosts();
            }
          },
        ),
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
        _loadPosts();
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
            const Icon(Icons.post_add_rounded, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'No Blog Posts Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No posts match your search query.'
                  : 'Start writing your first high-yield preparation blog post.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (ctx) => AdminBlogEditorScreen(categories: _categories)),
                );
                if (created == true) _loadPosts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Blog Post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(bool isDesktop) {
    return ListView.separated(
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final post = _posts[index];
        return _buildPostCard(post, isDesktop);
      },
    );
  }

  Widget _buildPostCard(CmsBlogPostModel post, bool isDesktop) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 90,
              height: 70,
              color: const Color(0xFFF1F5F9),
              child: post.featuredImageUrl != null && post.featuredImageUrl!.isNotEmpty
                  ? Image.network(
                      post.featuredImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                    )
                  : const Icon(Icons.article_rounded, color: Color(0xFF4F46E5), size: 30),
            ),
          ),
          const SizedBox(width: 16),

          // Post details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (post.categoryName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.categoryName!,
                          style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _buildStatusBadge(post.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  children: [
                    Text(
                      'By ${post.authorName}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '${post.readTimeMinutes} min read',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text('${post.viewsCount} views', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
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
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Preview Post',
                onPressed: () => context.push('/blog/${post.slug}'),
              ),
              IconButton(
                icon: Icon(
                  post.isPublished ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                  size: 20,
                  color: post.isPublished ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                ),
                tooltip: post.isPublished ? 'Unpublish to Draft' : 'Publish Live',
                onPressed: () => _togglePublish(post),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF4F46E5)),
                tooltip: 'Edit Post',
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AdminBlogEditorScreen(
                        postToEdit: post,
                        categories: _categories,
                      ),
                    ),
                  );
                  if (updated == true) _loadPosts();
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF64748B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val == 'duplicate') _duplicatePost(post);
                  if (val == 'delete') _confirmDelete(post);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 16, color: Color(0xFF4F46E5)),
                        SizedBox(width: 8),
                        Text('Duplicate Post', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                        SizedBox(width: 8),
                        Text('Delete Post', style: TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPub ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(4),
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
}
