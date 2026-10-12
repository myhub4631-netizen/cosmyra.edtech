import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';
import '../../models/promo_dropdown_model.dart';

/// Live Dropdown Promo Ad & App Download Banner Widget
/// Compact 3x12 ultra-sleek top notification strip.
/// Supports Cloudflare R2 direct automatic downloads when clicking Download App.
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

  /// Triggers direct automatic file download for Cloudflare R2 / APK links
  Future<void> _handleAction() async {
    final urlStr = _config?.actionUrl.trim() ?? '';
    if (urlStr.isEmpty) return;

    try {
      final uri = Uri.parse(urlStr);

      if (kIsWeb) {
        // Direct download trigger for Cloudflare R2 / Web
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      debugPrint('Error launching Cloudflare R2 download URL: $e');
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
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bgColor,
              bgColor.withValues(alpha: 0.90),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            height: 38,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 650;
                final String displayTitle = _config!.title.trim();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon / Badge Tag
                    if (isAppType) ...[
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(bannerIcon, color: accentColor, size: 13),
                      ),
                      const SizedBox(width: 6),
                    ],

                    if (_config!.badgeText.isNotEmpty && (!isMobile || !isAppType)) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _config!.badgeText.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Sleek Single Line Headline / Title Text
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 11 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Download Action Button (Cloudflare R2 Direct Download)
                    if (_config!.actionLabel.isNotEmpty && _config!.actionUrl.isNotEmpty) ...[
                      InkWell(
                        onTap: _handleAction,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAppType ? Icons.download_rounded : Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isMobile
                                    ? (isAppType ? 'Download APK' : _config!.actionLabel)
                                    : _config!.actionLabel,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Close (X) Dismiss Button
                    if (_config!.isDismissible)
                      InkWell(
                        onTap: () {
                          setState(() => _isDismissed = true);
                          widget.onDismiss?.call();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            color: textColor.withValues(alpha: 0.8),
                            size: 15,
                          ),
                        ),
                      ),
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
