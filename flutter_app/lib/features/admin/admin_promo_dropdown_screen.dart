import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import '../../shared/widgets/promo_dropdown_banner.dart';

class AdminPromoDropdownScreen extends StatefulWidget {
  final UserProfileModel? userProfile;

  const AdminPromoDropdownScreen({super.key, this.userProfile});

  @override
  State<AdminPromoDropdownScreen> createState() => _AdminPromoDropdownScreenState();
}

class _AdminPromoDropdownScreenState extends State<AdminPromoDropdownScreen> {
  PromoDropdownModel _config = PromoDropdownModel.defaultConfig();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _titleCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _actionLabelCtrl = TextEditingController();
  final _actionUrlCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _htmlContentCtrl = TextEditingController();
  final _badgeTextCtrl = TextEditingController();
  final _bgColorHexCtrl = TextEditingController();
  final _textColorHexCtrl = TextEditingController();
  final _accentColorHexCtrl = TextEditingController();

  String _selectedType = 'download_app';
  bool _isActive = true;
  bool _isDismissible = true;
  bool _autoExpandOnLoad = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _actionLabelCtrl.dispose();
    _actionUrlCtrl.dispose();
    _imageUrlCtrl.dispose();
    _htmlContentCtrl.dispose();
    _badgeTextCtrl.dispose();
    _bgColorHexCtrl.dispose();
    _textColorHexCtrl.dispose();
    _accentColorHexCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final model = await SupabaseService.fetchPromoDropdownSettings();
    if (mounted) {
      setState(() {
        _config = model;
        _isActive = model.isActive;
        _selectedType = model.bannerType;
        _titleCtrl.text = model.title;
        _textCtrl.text = model.text;
        _actionLabelCtrl.text = model.actionLabel;
        _actionUrlCtrl.text = model.actionUrl;
        _imageUrlCtrl.text = model.imageUrl;
        _htmlContentCtrl.text = model.htmlContent;
        _badgeTextCtrl.text = model.badgeText;
        _bgColorHexCtrl.text = model.bgColorHex;
        _textColorHexCtrl.text = model.textColorHex;
        _accentColorHexCtrl.text = model.accentColorHex;
        _isDismissible = model.isDismissible;
        _autoExpandOnLoad = model.autoExpandOnLoad;
        _isLoading = false;
      });
    }
  }

  void _updateLivePreview() {
    setState(() {
      _config = PromoDropdownModel(
        isActive: _isActive,
        bannerType: _selectedType,
        title: _titleCtrl.text,
        text: _textCtrl.text,
        actionLabel: _actionLabelCtrl.text,
        actionUrl: _actionUrlCtrl.text,
        imageUrl: _imageUrlCtrl.text,
        htmlContent: _htmlContentCtrl.text,
        badgeText: _badgeTextCtrl.text,
        bgColorHex: _bgColorHexCtrl.text,
        textColorHex: _textColorHexCtrl.text,
        accentColorHex: _accentColorHexCtrl.text,
        isDismissible: _isDismissible,
        autoExpandOnLoad: _autoExpandOnLoad,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  void _applyPreset(String preset) {
    if (preset == 'download_app') {
      _selectedType = 'download_app';
      _titleCtrl.text = '📱 Download Cosmyra NEET & JEE Official Android App';
      _textCtrl.text = 'Practice 50,000+ NTA questions, mock test series & PYQs anywhere on your phone!';
      _actionLabelCtrl.text = 'Download App (.apk)';
      _actionUrlCtrl.text = 'https://neet-jee.in/app-release.apk';
      _badgeTextCtrl.text = 'ANDROID APK';
      _bgColorHexCtrl.text = '4F46E5';
      _accentColorHexCtrl.text = '10B981';
      _htmlContentCtrl.clear();
    } else if (preset == 'offer') {
      _selectedType = 'offer';
      _titleCtrl.text = '🔥 Early Bird Offer: Up to 85% OFF Test Series!';
      _textCtrl.text = 'Get unlimited access to NEET & JEE 2026 all India test series with video solutions.';
      _actionLabelCtrl.text = 'Claim Offer Now';
      _actionUrlCtrl.text = 'https://neet-jee.in/pricing';
      _badgeTextCtrl.text = '85% OFF';
      _bgColorHexCtrl.text = '7C3AED';
      _accentColorHexCtrl.text = 'F59E0B';
      _htmlContentCtrl.clear();
    } else if (preset == 'promo_ad') {
      _selectedType = 'promo_ad';
      _titleCtrl.text = '⚡ Live All India NEET Rank Predictor & Mock Test';
      _textCtrl.text = 'Compete with thousands of aspirants nationwide and get detailed AI performance analytics.';
      _actionLabelCtrl.text = 'Explore Tests';
      _actionUrlCtrl.text = 'https://neet-jee.in/test-series';
      _badgeTextCtrl.text = 'PROMO AD';
      _bgColorHexCtrl.text = '0F172A';
      _accentColorHexCtrl.text = '3B82F6';
      _htmlContentCtrl.clear();
    } else if (preset == 'custom_html') {
      _selectedType = 'custom_html';
      _titleCtrl.text = '⭐ Custom HTML Announcement Bar';
      _textCtrl.text = 'Rich HTML formatted banner content';
      _actionLabelCtrl.text = 'View Details';
      _actionUrlCtrl.text = 'https://neet-jee.in';
      _badgeTextCtrl.text = 'HTML AD';
      _bgColorHexCtrl.text = '1E1B4B';
      _accentColorHexCtrl.text = 'EC4899';
      _htmlContentCtrl.text = '<span style="color:#FBBF24;font-weight:bold;">SPECIAL ANNOUNCEMENT:</span> Download our app or visit website for free PYQ practice tests!';
    }
    _updateLivePreview();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    _updateLivePreview();

    final success = await SupabaseService.savePromoDropdownSettings(_config);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(success ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  success
                      ? '✓ Top Dropdown Promo & App Banner published live to website!'
                      : 'Notice: Banner settings saved locally.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dropdown Banner & App Download Manager',
              style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Configure website top dropdown promo, app download link (.apk), offer banners & HTML ads',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded, size: 18),
              label: Text(_isSaving ? 'Publishing...' : 'Save & Publish Live', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live Banner Preview Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          color: const Color(0xFFF1F5F9),
                          child: Row(
                            children: [
                              const Icon(Icons.remove_red_eye_rounded, size: 18, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE WEBSITE DROPDOWN PREVIEW',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF334155), letterSpacing: 0.5),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _isActive ? 'ACTIVE ON WEBSITE' : 'INACTIVE / HIDDEN',
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PromoDropdownBanner(
                          forceVisible: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 2. Quick Presets Bar
                  Text(
                    'Quick Banner Presets',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click any preset below to instantly load template content for app downloads, offers, or ads',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.android_rounded, size: 18, color: Color(0xFF10B981)),
                        label: Text('📱 Download App (.apk)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        backgroundColor: _selectedType == 'download_app' ? const Color(0xFFEEF2FF) : Colors.white,
                        side: BorderSide(color: _selectedType == 'download_app' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
                        onPressed: () => _applyPreset('download_app'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.local_offer_rounded, size: 18, color: Color(0xFFF59E0B)),
                        label: Text('🏷️ Special Offer Banner', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        backgroundColor: _selectedType == 'offer' ? const Color(0xFFEEF2FF) : Colors.white,
                        side: BorderSide(color: _selectedType == 'offer' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
                        onPressed: () => _applyPreset('offer'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.campaign_rounded, size: 18, color: Color(0xFF3B82F6)),
                        label: Text('📢 Promo Ad Banner', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        backgroundColor: _selectedType == 'promo_ad' ? const Color(0xFFEEF2FF) : Colors.white,
                        side: BorderSide(color: _selectedType == 'promo_ad' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
                        onPressed: () => _applyPreset('promo_ad'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.code_rounded, size: 18, color: Color(0xFFEC4899)),
                        label: Text('💻 Custom HTML Code', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        backgroundColor: _selectedType == 'custom_html' ? const Color(0xFFEEF2FF) : Colors.white,
                        side: BorderSide(color: _selectedType == 'custom_html' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
                        onPressed: () => _applyPreset('custom_html'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 3. Configuration Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Switch & General Settings
                        Row(
                          children: [
                            Text(
                              'Banner Display Settings',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Text('Enable Banner on Website: ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                Switch(
                                  value: _isActive,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged: (val) {
                                    setState(() => _isActive = val);
                                    _updateLivePreview();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 28),

                        // Form Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth > 700;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Type & Badge Label
                                if (isWide)
                                  Row(
                                    children: [
                                      Expanded(child: _buildBannerTypeDropdown()),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildTextField(_badgeTextCtrl, 'Badge Label (e.g. ANDROID APK, OFFER, AD)', Icons.label_rounded)),
                                    ],
                                  )
                                else ...[
                                  _buildBannerTypeDropdown(),
                                  const SizedBox(height: 16),
                                  _buildTextField(_badgeTextCtrl, 'Badge Label (e.g. ANDROID APK, OFFER, AD)', Icons.label_rounded),
                                ],

                                const SizedBox(height: 16),

                                // Headline Title
                                _buildTextField(_titleCtrl, 'Headline / Title Text', Icons.title_rounded),

                                const SizedBox(height: 16),

                                // Description Text
                                _buildTextField(_textCtrl, 'Subtitle / Description Text', Icons.notes_rounded, maxLines: 2),

                                const SizedBox(height: 16),

                                // Action Button Label & URL
                                if (isWide)
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField(_actionLabelCtrl, 'Action Button Label (e.g. Download App, Claim Offer)', Icons.smart_button_rounded)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Stack(
                                          alignment: Alignment.centerRight,
                                          children: [
                                            _buildTextField(_actionUrlCtrl, 'Target Link URL (e.g. https://neet-jee.in/app-release.apk)', Icons.link_rounded),
                                            Positioned(
                                              right: 8,
                                              child: TextButton.icon(
                                                onPressed: () {
                                                  _actionUrlCtrl.text = 'https://neet-jee.in/app-release.apk';
                                                  _updateLivePreview();
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: const Color(0xFF4F46E5),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                ),
                                                icon: const Icon(Icons.android_rounded, size: 14),
                                                label: const Text('Use APK Link', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildTextField(_actionLabelCtrl, 'Action Button Label (e.g. Download App, Claim Offer)', Icons.smart_button_rounded),
                                  const SizedBox(height: 16),
                                  _buildTextField(_actionUrlCtrl, 'Target Link URL (e.g. https://neet-jee.in/app-release.apk)', Icons.link_rounded),
                                ],

                                const SizedBox(height: 16),

                                // Optional Image URL & HTML Code
                                _buildTextField(_imageUrlCtrl, 'Optional Promo Image URL / App Icon', Icons.image_rounded),

                                const SizedBox(height: 16),

                                // Custom HTML Code Textfield
                                _buildTextField(
                                  _htmlContentCtrl,
                                  'Custom HTML Text / Markup (Optional - overrides text if provided)',
                                  Icons.html_rounded,
                                  maxLines: 3,
                                  fontFamily: 'monospace',
                                ),

                                const SizedBox(height: 24),
                                Text('Visual Theme & Color Styling', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                                const SizedBox(height: 12),

                                // Color Customizer Fields
                                if (isWide)
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField(_bgColorHexCtrl, 'Background Color Hex (e.g. 4F46E5)', Icons.palette_rounded)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildTextField(_textColorHexCtrl, 'Text Color Hex (e.g. FFFFFF)', Icons.format_color_text_rounded)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildTextField(_accentColorHexCtrl, 'Button Accent Color Hex (e.g. 10B981)', Icons.color_lens_rounded)),
                                    ],
                                  )
                                else ...[
                                  _buildTextField(_bgColorHexCtrl, 'Background Color Hex (e.g. 4F46E5)', Icons.palette_rounded),
                                  const SizedBox(height: 12),
                                  _buildTextField(_textColorHexCtrl, 'Text Color Hex (e.g. FFFFFF)', Icons.format_color_text_rounded),
                                  const SizedBox(height: 12),
                                  _buildTextField(_accentColorHexCtrl, 'Button Accent Color Hex (e.g. 10B981)', Icons.color_lens_rounded),
                                ],

                                const SizedBox(height: 20),

                                // Options Checkboxes
                                CheckboxListTile(
                                  value: _isDismissible,
                                  title: Text('Allow users to dismiss / close banner with (X) button', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  activeColor: const Color(0xFF4F46E5),
                                  onChanged: (val) {
                                    setState(() => _isDismissible = val ?? true);
                                    _updateLivePreview();
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildBannerTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Banner Category / Type',
        prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF64748B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const [
        DropdownMenuItem(value: 'download_app', child: Text('📱 Download App (.apk)')),
        DropdownMenuItem(value: 'offer', child: Text('🏷️ Special Offer Banner')),
        DropdownMenuItem(value: 'promo_ad', child: Text('📢 Promo Ad Banner')),
        DropdownMenuItem(value: 'custom_html', child: Text('💻 Custom HTML Code Text')),
        DropdownMenuItem(value: 'custom_text', child: Text('📝 Custom Text Announcement')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedType = val);
          _updateLivePreview();
        }
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? fontFamily,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: fontFamily != null ? TextStyle(fontFamily: fontFamily, fontSize: 12) : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (_) => _updateLivePreview(),
    );
  }
}
