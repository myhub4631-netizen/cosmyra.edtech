import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import '../legal/terms_of_service_screen.dart';

class AdminTermsManagerScreen extends StatefulWidget {
  final UserProfileModel? userProfile;

  const AdminTermsManagerScreen({super.key, this.userProfile});

  @override
  State<AdminTermsManagerScreen> createState() => _AdminTermsManagerScreenState();
}

class _AdminTermsManagerScreenState extends State<AdminTermsManagerScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadTerms() async {
    setState(() => _isLoading = true);
    final text = await SupabaseService.fetchTermsOfService();
    setState(() {
      _contentController.text = text.isNotEmpty ? text : defaultTermsOfServiceText;
      _isLoading = false;
    });
  }

  Future<void> _saveTerms() async {
    setState(() {
      _isSaving = true;
      _statusMessage = '';
    });

    final success = await SupabaseService.saveTermsOfService(_contentController.text);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _statusMessage = success
            ? 'Terms of Service updated & published successfully!'
            : 'Saved to local cache (Database update pending).';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusMessage),
          backgroundColor: success ? const Color(0xFF0D7A53) : const Color(0xFFE11D48),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Terms of Service'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: 'View Live Public Terms',
            icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF0D7A53)),
            onPressed: () => context.go('/terms'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveTerms,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save & Publish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7A53),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFF0D7A53)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Manage the official Cosmyra NEET JEE Terms of Service content here. Changes saved here take effect immediately on https://neet-jee.in/terms and inside the mobile application.',
                                style: TextStyle(color: Color(0xFF1B5E20), fontSize: 13.5, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Terms Text Content',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _contentController.text = defaultTermsOfServiceText;
                                    });
                                  },
                                  icon: const Icon(Icons.restore, size: 16),
                                  label: const Text('Reset to Default'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _contentController,
                              maxLines: 25,
                              style: const TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
                              decoration: InputDecoration(
                                hintText: 'Enter Terms of Service text here...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF0D7A53), width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/admin'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveTerms,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Save & Publish Live'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D7A53),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
