import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/seo_tracking_service.dart';

class BlogPostScreen extends StatefulWidget {
  final String slug;

  const BlogPostScreen({super.key, required this.slug});

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  bool _isLoading = true;
  CmsBlogPostModel? _post;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void didUpdateWidget(covariant BlogPostScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _loadPost();
    }
  }

  Future<void> _loadPost() async {
    setState(() => _isLoading = true);
    final post = await SupabaseService.fetchBlogPostBySlug(widget.slug);
    if (mounted) {
      setState(() {
        _post = post;
        _isLoading = false;
      });
      if (post != null) {
        SupabaseService.incrementBlogPostViews(post.id);
        SeoTrackingService.applyBlogSeo(post);
      }
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
              context.go('/blog');
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
            onPressed: () => context.go('/blog'),
            child: const Text('All Articles', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => context.go('/practice'),
            child: const Text('Practice', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? _buildNotFoundView()
              : _buildPostContent(),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text('Article Not Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('The article "/blog/${widget.slug}" does not exist or has been unpublished.', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/blog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to Blog'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    final post = _post!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Post Header Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.go('/'),
                          child: const Text('Home', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        ),
                        const Text('  /  ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        InkWell(
                          onTap: () => context.go('/blog'),
                          child: const Text('Blog', style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 13)),
                        ),
                        if (post.categoryName != null) ...[
                          const Text('  /  ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          Text(post.categoryName!, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      post.title,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.25, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),

                    // Metadata Row
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFF4F46E5),
                              child: Icon(Icons.person_rounded, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(post.authorName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        Text(_formatDate(post.publishedAt ?? post.createdAt), style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                        Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        Text('${post.readTimeMinutes} min read', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                        Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_outlined, size: 15, color: Color(0xFFCBD5E1)),
                            const SizedBox(width: 4),
                            Text('${post.viewsCount} views', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Article Container
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Cover Image
                    if (post.featuredImageUrl != null && post.featuredImageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          post.featuredImageUrl!,
                          width: double.infinity,
                          height: 380,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Markdown Article Body
                    MarkdownBody(
                      data: post.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.4),
                        h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.4),
                        h3: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF334155), height: 1.4),
                        p: const TextStyle(fontSize: 15.5, color: Color(0xFF334155), height: 1.75),
                        listBullet: const TextStyle(fontSize: 15.5, color: Color(0xFF334155)),
                        blockquoteDecoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          border: const Border(left: BorderSide(color: Color(0xFF4F46E5), width: 4)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        code: const TextStyle(fontFamily: 'monospace', backgroundColor: Color(0xFFF1F5F9), fontSize: 13),
                      ),
                    ),

                    // Tags chips
                    if (post.tags.isNotEmpty) ...[
                      const SizedBox(height: 36),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('Topics & Tags:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: post.tags.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text('#$t', style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Footer
          _buildFooter(),
        ],
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
              _footerLink('All Articles', '/blog'),
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

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
