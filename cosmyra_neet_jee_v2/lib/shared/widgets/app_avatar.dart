import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import 'smart_image.dart';

class AppAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final BoxBorder? border;

  const AppAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 36,
    this.backgroundColor,
    this.textStyle,
    this.border,
  });

  factory AppAvatar.fromProfile(
    UserProfileModel? profile, {
    double size = 36,
    Color? backgroundColor,
    TextStyle? textStyle,
    BoxBorder? border,
  }) {
    String? resolvedUrl = profile?.avatarUrl;
    final currentEmail = profile?.email.toLowerCase().trim() ?? '';
    final sessionEmail = SupabaseService.activeUserSession?.email.toLowerCase().trim() ?? '';
    final authEmail = SupabaseService.client.auth.currentUser?.email?.toLowerCase().trim() ?? '';

    final isCurrentUserOrAdmin = profile == null ||
        currentEmail.isEmpty ||
        currentEmail == sessionEmail ||
        currentEmail == authEmail;

    if ((resolvedUrl == null || resolvedUrl.trim().isEmpty) && isCurrentUserOrAdmin) {
      resolvedUrl = SupabaseService.activeUserSession?.avatarUrl;
    }
    if ((resolvedUrl == null || resolvedUrl.trim().isEmpty) && isCurrentUserOrAdmin) {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final meta = user.userMetadata;
        if (meta != null) {
          resolvedUrl = (meta['avatar_url'] ?? meta['picture'] ?? meta['photo_url'] ?? meta['avatar'] ?? meta['picture_url'])?.toString();
        }
      }
    }

    final resolvedName = (profile?.fullName != null && profile!.fullName.trim().isNotEmpty)
        ? profile.fullName
        : (profile?.email.isNotEmpty == true ? profile!.email.split('@').first : 'User');

    return AppAvatar(
      avatarUrl: resolvedUrl,
      name: resolvedName,
      size: size,
      backgroundColor: backgroundColor,
      textStyle: textStyle,
      border: border,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = avatarUrl?.trim() ?? '';
    final hasImage = cleanUrl.isNotEmpty;

    // Calculate initials
    final parts = name.trim().split(RegExp(r'\s+'));
    String initials = 'U';
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    final bgColor = backgroundColor ?? const Color(0xFF6366F1);

    final fallbackWidget = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Text(
        initials,
        style: textStyle ??
            TextStyle(
              color: Colors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
            ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? SmartImage(
              url: cleanUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              fallback: fallbackWidget,
            )
          : fallbackWidget,
    );
  }
}
