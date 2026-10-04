import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';
import '../../models/promo_dropdown_model.dart';

/// Live Dropdown Promo Ad & App Download Banner Widget
/// Renders dynamically at the top of the website / app when enabled by Admin.
class PromoDropdownBanner extends StatefulWidget {
  final VoidCallback? onDismiss;
  final bool forceVisible;

  const PromoDropdownBanner({
    super.key,
    this.onDismiss,
    this.forceVisible = false,
  });

  @override
  State<PromoDropdownBanner> createState() => _PromoDropdownBannerState();
}

class _PromoDropdownBannerState extends State<PromoDropdownBanner> {
  PromoDropdownModel? _config;
  bool _isLoading = true;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await SupabaseService.fetchPromoDropdownSettings();
    if (mounted) {
      setState(() {
        _config = cfg;
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String hex, Color defaultColor) {
    try {
      String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        clean = 'FF$clean';
      }
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  Future<void> _handleAction() async {
    final urlStr = _config?.actionUrl.trim() ?? '';
    if (urlStr.isEmpty) return;

    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching promo action URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _config == null) return const SizedBox.shrink();
    if (!_config!.isActive && !widget.forceVisible) return const SizedBox.shrink();
    if (_isDismissed && !widget.forceVisible) return const SizedBox.shrink();

    final bgColor = _parseColor(_config!.bgColorHex, const Color(0xFF4F46E5));
    final textColor = _parseColor(_config!.textColorHex, Colors.white);
    final accentColor = _parseColor(_config!.accentColorHex, const Color(0xFF10B981));

    final bool isAppType = _config!.bannerType == 'download_app' || _config!.actionUrl.contains('.apk');
    final IconData bannerIcon = isAppType
        ? Icons.android_rounded
        : _config!.bannerType == 'offer'
            ? Icons.local_offer_rounded
            : _config!.bannerType == 'promo_ad'
                ? Icons.campaign_rounded
                : Icons.auto_awesome_rounded;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bgColor,
              bgColor.withOpacity(0.85),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: const BoxConstraints(minHeight: 46),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 650;

                if (isMobile) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(bannerIcon, color: accentColor, size: 18),
                          ),
                          const SizedBox(width: 8),
                          if (_config!.badgeText.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _config!.badgeText.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _config!.title,
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_config!.isDismissible)
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: textColor.withOpacity(0.8), size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() => _isDismissed = true);
                                widget.onDismiss?.call();
                              },
                            ),
                        ],
                      ),
                      if (_config!.text.isNotEmpty || _config!.htmlContent.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _config!.text.isNotEmpty ? _config!.text : _config!.htmlContent.replaceAll(RegExp(r'<[^>]*>'), ''),
                          style: GoogleFonts.inter(
                            color: textColor.withOpacity(0.9),
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_config!.actionLabel.isNotEmpty && _config!.actionUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: _handleAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: Icon(isAppType ? Icons.download_rounded : Icons.arrow_forward_rounded, size: 14),
                            label: Text(
                              _config!.actionLabel,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }

                // Desktop / Tablet Layout
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(bannerIcon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    if (_config!.badgeText.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          _config!.badgeText.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _config!.title,
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_config!.text.isNotEmpty)
                            Text(
                              _config!.text,
                              style: GoogleFonts.inter(
                                color: textColor.withOpacity(0.85),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (_config!.actionLabel.isNotEmpty && _config!.actionUrl.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _handleAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: Icon(isAppType ? Icons.download_rounded : Icons.arrow_forward_rounded, size: 16),
                        label: Text(
                          _config!.actionLabel,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                    if (_config!.isDismissible) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textColor.withOpacity(0.8), size: 20),
                        tooltip: 'Dismiss Banner',
                        onPressed: () {
                          setState(() => _isDismissed = true);
                          widget.onDismiss?.call();
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
