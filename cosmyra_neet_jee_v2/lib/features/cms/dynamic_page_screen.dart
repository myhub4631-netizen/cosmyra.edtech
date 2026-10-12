import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/seo_tracking_service.dart';

class DynamicPageScreen extends StatefulWidget {
  final String slug;

  const DynamicPageScreen({super.key, required this.slug});

  @override
  State<DynamicPageScreen> createState() => _DynamicPageScreenState();
}

class _DynamicPageScreenState extends State<DynamicPageScreen> {
  bool _isLoading = true;
  CmsPageModel? _page;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void didUpdateWidget(covariant DynamicPageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() => _isLoading = true);
    final page = await SupabaseService.fetchCmsPageBySlug(widget.slug);
    if (mounted) {
      setState(() {
        _page = page;
        _isLoading = false;
      });
      if (page != null) {
        SeoTrackingService.applyPageSeo(page);
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
            onPressed: () => context.go('/blog'),
            child: const Text('Blog', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
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
          : _page == null
              ? _buildNotFoundView()
              : _buildPageContent(),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text('Page Not Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('The page "/pages/${widget.slug}" does not exist or has been moved.', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    final page = _page!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
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
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.go('/'),
                          child: const Text('Home', style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 13)),
                        ),
                        const Text('  /  ', style: TextStyle(color: Color(0xFF818CF8), fontSize: 13)),
                        Text(page.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page.title,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Last updated: ${_formatDate(page.updatedAt)}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Article / Content Card
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
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (page.featuredImageUrl != null && page.featuredImageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          page.featuredImageUrl!,
                          width: double.infinity,
                          height: 320,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    MarkdownBody(
                      data: page.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.4),
                        h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.4),
                        h3: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF334155), height: 1.4),
                        p: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.7),
                        listBullet: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
                        blockquoteDecoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          border: const Border(left: BorderSide(color: Color(0xFF4F46E5), width: 4)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        code: const TextStyle(fontFamily: 'monospace', backgroundColor: Color(0xFFF1F5F9), fontSize: 13),
                      ),
                    ),
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
              _footerLink('About Us', '/about-us'),
              _footerLink('Blog', '/blog'),
              _footerLink('Privacy Policy', '/privacy-policy'),
              _footerLink('Terms of Service', '/terms-of-service'),
              _footerLink('Contact Us', '/contact-us'),
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
