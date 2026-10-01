import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';

class AdminUpdatesManagerScreen extends StatefulWidget {
  const AdminUpdatesManagerScreen({Key? key}) : super(key: key);

  @override
  State<AdminUpdatesManagerScreen> createState() => _AdminUpdatesManagerScreenState();
}

class _AdminUpdatesManagerScreenState extends State<AdminUpdatesManagerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _updates = [];

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

  Future<void> _deleteUpdate(String id, String version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Text('Delete Release Entry?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete update "$version"?\n\nThis will permanently remove this entry from Supabase system_config storage and local cache to free up space.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: Text('Delete & Free Storage', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await SupabaseService.deleteAppUpdate(id);
      await _loadUpdates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✓ Update entry deleted. Supabase storage freed.' : 'Notice: Entry removed from cache.'),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openUpdateEditor({Map<String, dynamic>? item}) {
    final versionCtrl = TextEditingController(text: item?['version'] ?? 'v1.1.7');
    final titleCtrl = TextEditingController(text: item?['title'] ?? '');
    final dateCtrl = TextEditingController(text: item?['date'] ?? DateTime.now().toString().split(' ')[0]);
    final tagCtrl = TextEditingController(text: item?['tag'] ?? 'Release');
    final highlightsCtrl = TextEditingController(
      text: (item?['highlights'] as List? ?? []).join('\n'),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item == null ? 'Add New Release Update' : 'Edit Release Update',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: versionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Version Badge (e.g. v1.1.7)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Release Date (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Release Title',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: tagCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tag (Release/Feature)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: highlightsCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Changelog Highlights (1 per line)',
                  hintText: 'Reclaimed side gaps on mobile\nUpdated AppBar titleSpacing\nStreamlined icon badges',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final version = versionCtrl.text.trim();
                      if (title.isEmpty || version.isEmpty) return;

                      final points = highlightsCtrl.text
                          .split('\n')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final updateData = {
                        'id': item?['id'] ?? 'upd_${DateTime.now().millisecondsSinceEpoch}',
                        'version': version,
                        'date': dateCtrl.text.trim(),
                        'title': title,
                        'tag': tagCtrl.text.trim(),
                        'highlights': points,
                      };

                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      await SupabaseService.saveAppUpdate(updateData);
                      await _loadUpdates();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Release update saved and published.'),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Text(item == null ? 'Publish Update' : 'Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        title: Text(
          'App Updates & Changelog Manager',
          style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _openUpdateEditor(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('+ Add New Update', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_rounded, color: Color(0xFF2563EB), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supabase Cloud Storage & Updates Sync',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF)),
                          ),
                          Text(
                            'Manage release notes shown at neet-jee.in/updates. Delete older entries to clean up Supabase system_config storage.',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3B82F6)),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/updates'),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('View Live /updates'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Updates List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                    : _updates.isEmpty
                        ? const Center(child: Text('No release updates added.'))
                        : ListView.separated(
                            itemCount: _updates.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _updates[index];
                              final id = (item['id'] ?? '').toString();
                              final version = (item['version'] ?? '').toString();
                              final date = (item['date'] ?? '').toString();
                              final title = (item['title'] ?? '').toString();
                              final tag = (item['tag'] ?? 'Release').toString();
                              final highlights = (item['highlights'] as List? ?? []);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        version,
                                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                title,
                                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(tag, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$date • ${highlights.length} Highlights',
                                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit Update',
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 20),
                                      onPressed: () => _openUpdateEditor(item: item),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Update (Free Storage)',
                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                      onPressed: () => _deleteUpdate(id, version),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
