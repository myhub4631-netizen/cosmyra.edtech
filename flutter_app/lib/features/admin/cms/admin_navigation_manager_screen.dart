import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../core/services/supabase_service.dart';

class AdminNavigationManagerScreen extends StatefulWidget {
  final UserProfileModel? userProfile;

  const AdminNavigationManagerScreen({super.key, this.userProfile});

  @override
  State<AdminNavigationManagerScreen> createState() => _AdminNavigationManagerScreenState();
}

class _AdminNavigationManagerScreenState extends State<AdminNavigationManagerScreen> {
  bool _isLoading = true;
  List<CmsNavigationMenuModel> _menus = [];
  String _selectedMenuKey = 'header_main';
  List<CmsNavigationItemModel> _items = [];

  List<CmsPageModel> _availablePages = [];
  List<CmsBlogPostModel> _availableBlogs = [];

  final List<Map<String, String>> _appRoutes = [
    {'label': 'Home', 'route': '/'},
    {'label': 'Custom Practice', 'route': '/practice'},
    {'label': 'Mock Tests', 'route': '/mock-tests'},
    {'label': 'Test Series', 'route': '/test-series'},
    {'label': 'PYQ Papers', 'route': '/pyq'},
    {'label': 'Pricing & Plans', 'route': '/pricing'},
    {'label': 'Blog & Updates', 'route': '/blog'},
    {'label': 'Leaderboard', 'route': '/leaderboard'},
    {'label': 'Student Dashboard', 'route': '/dashboard'},
    {'label': 'Profile Settings', 'route': '/profile'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final menus = await SupabaseService.fetchNavigationMenus();
    final pages = await SupabaseService.fetchCmsPages(status: 'published');
    final blogs = await SupabaseService.fetchBlogPosts(status: 'published');

    if (mounted) {
      setState(() {
        _menus = menus;
        _availablePages = pages;
        _availableBlogs = blogs;
        if (menus.isNotEmpty && !menus.any((m) => m.key == _selectedMenuKey)) {
          _selectedMenuKey = menus.first.key;
        }
      });
      await _loadMenuItems();
    }
  }

  Future<void> _loadMenuItems() async {
    final currentMenu = _menus.firstWhere(
      (m) => m.key == _selectedMenuKey,
      orElse: () => CmsNavigationMenuModel(id: '', key: _selectedMenuKey, name: '', createdAt: DateTime.now()),
    );

    if (currentMenu.id.isNotEmpty) {
      final items = await SupabaseService.fetchNavigationItems(currentMenu.id);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility(CmsNavigationItemModel item) async {
    final updated = item.copyWith(isVisible: !item.isVisible);
    final saved = await SupabaseService.saveNavigationItem(updated);
    if (saved != null && mounted) {
      _loadMenuItems();
    }
  }

  Future<void> _moveItem(int index, int delta) async {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _items.length) return;

    final reordered = List<CmsNavigationItemModel>.from(_items);
    final item = reordered.removeAt(index);
    reordered.insert(newIndex, item);

    setState(() => _items = reordered);
    await SupabaseService.reorderNavigationItems(reordered);
  }

  Future<void> _deleteItem(CmsNavigationItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Menu Item?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Remove "${item.label}" from this navigation menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      await SupabaseService.deleteNavigationItem(item.id);
      _loadMenuItems();
    }
  }

  Future<void> _showAddOrEditItemDialog({CmsNavigationItemModel? itemToEdit}) async {
    final isEditing = itemToEdit != null;
    final currentMenu = _menus.firstWhere((m) => m.key == _selectedMenuKey);

    final labelCtrl = TextEditingController(text: itemToEdit?.label ?? '');
    final destCtrl = TextEditingController(text: itemToEdit?.destination ?? '');
    String linkType = itemToEdit?.linkType ?? 'page';
    bool openInNewTab = itemToEdit?.openInNewTab ?? false;
    bool isVisible = itemToEdit?.isVisible ?? true;

    String? selectedPageSlug = linkType == 'page' ? itemToEdit?.destination.replaceAll('/pages/', '') : null;
    String? selectedBlogSlug = linkType == 'blog' ? itemToEdit?.destination.replaceAll('/blog/', '') : null;
    String? selectedRoute = linkType == 'route' ? itemToEdit?.destination : null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Display Label *',
                      hintText: 'e.g. About Us, Test Series, PYQs',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link Type
                  const Text('Link Destination Type:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: linkType,
                    isDense: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'page', child: Text('Existing CMS Page')),
                      DropdownMenuItem(value: 'blog', child: Text('Existing Blog Post')),
                      DropdownMenuItem(value: 'route', child: Text('App Internal Screen / Route')),
                      DropdownMenuItem(value: 'custom_url', child: Text('Custom External URL')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          linkType = val;
                          destCtrl.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Sub-selector based on link type
                  if (linkType == 'page') ...[
                    DropdownButtonFormField<String>(
                      value: selectedPageSlug,
                      hint: const Text('Select a Page'),
                      isDense: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _availablePages.map((p) => DropdownMenuItem(value: p.slug, child: Text(p.title))).toList(),
                      onChanged: (slug) {
                        setDialogState(() {
                          selectedPageSlug = slug;
                          if (slug != null) {
                            destCtrl.text = '/pages/$slug';
                            if (labelCtrl.text.isEmpty) {
                              final p = _availablePages.firstWhere((e) => e.slug == slug);
                              labelCtrl.text = p.title;
                            }
                          }
                        });
                      },
                    ),
                  ] else if (linkType == 'blog') ...[
                    DropdownButtonFormField<String>(
                      value: selectedBlogSlug,
                      hint: const Text('Select a Blog Post'),
                      isDense: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _availableBlogs.map((b) => DropdownMenuItem(value: b.slug, child: Text(b.title, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (slug) {
                        setDialogState(() {
                          selectedBlogSlug = slug;
                          if (slug != null) {
                            destCtrl.text = '/blog/$slug';
                            if (labelCtrl.text.isEmpty) {
                              final b = _availableBlogs.firstWhere((e) => e.slug == slug);
                              labelCtrl.text = b.title;
                            }
                          }
                        });
                      },
                    ),
                  ] else if (linkType == 'route') ...[
                    DropdownButtonFormField<String>(
                      value: selectedRoute,
                      hint: const Text('Select App Screen'),
                      isDense: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _appRoutes.map((r) => DropdownMenuItem(value: r['route'], child: Text('${r['label']} (${r['route']})'))).toList(),
                      onChanged: (route) {
                        setDialogState(() {
                          selectedRoute = route;
                          if (route != null) {
                            destCtrl.text = route;
                            if (labelCtrl.text.isEmpty) {
                              final r = _appRoutes.firstWhere((e) => e['route'] == route);
                              labelCtrl.text = r['label']!;
                            }
                          }
                        });
                      },
                    ),
                  ] else ...[
                    TextField(
                      controller: destCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Destination URL *',
                        hintText: 'https://...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Open in new tab
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Open in new browser tab', style: TextStyle(fontSize: 13)),
                    value: openInNewTab,
                    onChanged: (val) => setDialogState(() => openInNewTab = val ?? false),
                  ),

                  // Visible
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Show item in navigation (Visible)', style: TextStyle(fontSize: 13)),
                    value: isVisible,
                    onChanged: (val) => setDialogState(() => isVisible = val ?? true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (labelCtrl.text.trim().isEmpty || destCtrl.text.trim().isEmpty) return;

                final item = CmsNavigationItemModel(
                  id: itemToEdit?.id ?? '',
                  menuId: currentMenu.id,
                  label: labelCtrl.text.trim(),
                  linkType: linkType,
                  destination: destCtrl.text.trim(),
                  sortOrder: itemToEdit?.sortOrder ?? (_items.length + 1),
                  isVisible: isVisible,
                  openInNewTab: openInNewTab,
                  createdAt: itemToEdit?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await SupabaseService.saveNavigationItem(item);
                if (ctx.mounted) {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              child: Text(isEditing ? 'Save Changes' : 'Add Item'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      _loadMenuItems();
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
              child: const Icon(Icons.menu_open_rounded, color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Navigation & Menus (CMS)',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddOrEditItemDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Menu Item', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu selector tabs
                _buildMenuSelectorBar(),
                const SizedBox(height: 20),

                // Items list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _items.isEmpty
                          ? _buildEmptyState()
                          : _buildItemsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.layers_outlined, size: 20, color: Color(0xFF4F46E5)),
          const SizedBox(width: 12),
          const Text('Select Navigation Location:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMenuKey,
                items: _menus.map((m) {
                  return DropdownMenuItem(
                    value: m.key,
                    child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMenuKey = val;
                      _isLoading = true;
                    });
                    _loadMenuItems();
                  }
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh Menu',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadMenuItems();
            },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.list_alt_rounded, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text('No Items in this Menu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          const Text('Add links to your published pages, blogs, or app routes.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddOrEditItemDialog(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add First Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final item = _items[index];
        final isFirst = index == 0;
        final isLast = index == _items.length - 1;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              // Order buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: isFirst ? null : () => _moveItem(index, -1),
                    child: Icon(Icons.keyboard_arrow_up_rounded, size: 20, color: isFirst ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  ),
                  InkWell(
                    onTap: isLast ? null : () => _moveItem(index, 1),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: isLast ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: item.isVisible ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            decoration: item.isVisible ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.linkType.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                          ),
                        ),
                        if (item.openInNewTab) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF64748B)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.destination,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),

              // Visibility switch
              IconButton(
                icon: Icon(
                  item.isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: item.isVisible ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                ),
                tooltip: item.isVisible ? 'Hide from Menu' : 'Show in Menu',
                onPressed: () => _toggleVisibility(item),
              ),

              // Edit
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF4F46E5)),
                tooltip: 'Edit Link',
                onPressed: () => _showAddOrEditItemDialog(itemToEdit: item),
              ),

              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFDC2626)),
                tooltip: 'Delete Link',
                onPressed: () => _deleteItem(item),
              ),
            ],
          ),
        );
      },
    );
  }
}
