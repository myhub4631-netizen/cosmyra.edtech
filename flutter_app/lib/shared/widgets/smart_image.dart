import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SmartImage extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? fallback;

  const SmartImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url?.trim() ?? '';
    final defaultFallback = fallback ?? const Icon(Icons.image_outlined, size: 24, color: Colors.grey);

    if (cleanUrl.isEmpty) return defaultFallback;

    final widgetKey = ValueKey(cleanUrl);

    // Check if SVG format
    final bool isSvg = cleanUrl.toLowerCase().contains('.svg') || cleanUrl.startsWith('data:image/svg+xml');

    if (isSvg) {
      if (cleanUrl.startsWith('data:image/svg+xml')) {
        try {
          if (cleanUrl.contains(';base64,')) {
            final base64Content = cleanUrl.split(';base64,').last;
            final Uint8List bytes = base64Decode(base64Content);
            return SvgPicture.memory(
              bytes,
              key: widgetKey,
              height: height,
              width: width,
              fit: fit,
              placeholderBuilder: (_) => SizedBox(height: height, width: width),
            );
          } else if (cleanUrl.contains(',')) {
            final xmlStr = Uri.decodeComponent(cleanUrl.split(',').last);
            return SvgPicture.string(
              xmlStr,
              key: widgetKey,
              height: height,
              width: width,
              fit: fit,
            );
          }
        } catch (e) {
          debugPrint('Error parsing SVG data URL: $e');
        }
      }

      // Network SVG with gapless placeholder to prevent flickering on parent rebuilds
      return SvgPicture.network(
        cleanUrl,
        key: widgetKey,
        height: height,
        width: width,
        fit: fit,
        placeholderBuilder: (_) => SizedBox(height: height, width: width),
      );
    }

    // Base64 Raster Image (png/jpg/webp)
    if (cleanUrl.startsWith('data:image/')) {
      try {
        final base64Content = cleanUrl.split(',').last;
        final Uint8List bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          key: widgetKey,
          height: height,
          width: width,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => defaultFallback,
        );
      } catch (e) {
        debugPrint('Error decoding raster base64 image: $e');
      }
    }

    // Standard Network Raster Image with gaplessPlayback to prevent flickering on parent rebuilds
    return Image.network(
      cleanUrl,
      key: widgetKey,
      height: height,
      width: width,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => defaultFallback,
    );
  }
}
