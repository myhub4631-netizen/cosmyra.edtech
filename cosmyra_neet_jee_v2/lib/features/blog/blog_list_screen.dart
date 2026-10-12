import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<CmsBlogPostModel> _posts = [];
  List<CmsBlogCategoryModel> _categories = [];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await SupabaseService.fetchBlogCategories();
    final posts = await SupabaseService.fetchBlogPosts(
      status: 'published',
      categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
      search: _searchController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _categories = cats;
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              context.go('/');
            }
          },
        ),
        title: InkWell(
          onTap: () => context.go('/'),
          child: Image.asset(
            'assets/images/cosmyra_logo.png',
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text('Cosmyra NEET JEE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Home', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => context.go('/practice'),
            child: const Text('Practice', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => context.go('/test-series'),
            child: const Text('Test Series', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.go('/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Get Started'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.4)),
                        ),
                        child: const Text(
                          'COSMYRA PREPARATION BLOG',
                          style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Insights, Strategies & High-Yield Guides',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Master NEET & JEE with expert tips, syllabus breakdowns, and test-taking strategies from top faculties.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14.5, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Search bar
                      Container(
                        constraints: const BoxConstraints(maxWidth: 520),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _loadData(),
                          decoration: InputDecoration(
                            hintText: 'Search articles by topic, exam, chapter...',
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF4F46E5)),
                              onPressed: _loadData,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content Area
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Filter Chips
                      _buildCategoryChips(),
                      const SizedBox(height: 28),

                      // Posts Grid or Loading
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_posts.isEmpty)
                        _buildEmptyPosts()
                      else
                        _buildPostsGrid(),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _categoryChip('All Articles', 'all'),
          ..._categories.map((c) => _categoryChip(c.name, c.id)),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String id) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF4F46E5),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
        onSelected: (_) {
          setState(() => _selectedCategory = id);
          _loadData();
        },
      ),
    );
  }

  Widget _buildEmptyPosts() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text('No Articles Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          const Text('Try selecting a different category or search term.', style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _posts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (ctx, index) {
            final post = _posts[index];
            return _buildBlogCard(post);
          },
        );
      },
    );
  }

  Widget _buildBlogCard(CmsBlogPostModel post) {
    return InkWell(
      onTap: () => context.push('/blog/${post.slug}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Container(
              height: 170,
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              child: post.featuredImageUrl != null && post.featuredImageUrl!.isNotEmpty
                  ? Image.network(
                      post.featuredImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8))),
                    )
                  : const Center(child: Icon(Icons.article_outlined, size: 40, color: Color(0xFF4F46E5))),
            ),

            // Content details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.categoryName != null) ...[
                      Text(
                        post.categoryName!.toUpperCase(),
                        style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      post.title,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (post.excerpt != null && post.excerpt!.isNotEmpty)
                      Expanded(
                        child: Text(
                          post.excerpt!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.authorName,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${post.readTimeMinutes} min',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Image.asset('assets/images/cosmyra_logo.png', height: 28, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _footerLink('Home', '/'),
              _footerLink('About Us', '/about-us'),
              _footerLink('Practice', '/practice'),
              _footerLink('Test Series', '/test-series'),
              _footerLink('Privacy Policy', '/privacy-policy'),
              _footerLink('Terms of Service', '/terms-of-service'),
            ],
          ),
          const SizedBox(height: 12),
          const Text('© 2026 Cosmyra Technologies Pvt. Ltd. All rights reserved.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _footerLink(String label, String route) {
    return InkWell(
      onTap: () => context.go(route),
      child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
    );
  }
}
