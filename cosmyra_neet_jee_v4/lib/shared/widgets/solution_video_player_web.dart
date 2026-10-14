// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

bool registerWebVideoView(String viewId, String url, bool autoPlay) {
  if (url.trim().isEmpty) return false;

  final cleanUrl = url.trim();
  final isYouTube = cleanUrl.contains('youtube.com') || cleanUrl.contains('youtu.be');
  final isVimeo = cleanUrl.contains('vimeo.com');

  if (isYouTube) {
    final embedUrl = _getYouTubeEmbedUrl(cleanUrl);
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
        ..allowFullscreen = true;
      return iframe;
    });
    return true;
  } else if (isVimeo) {
    final embedUrl = _getVimeoEmbedUrl(cleanUrl);
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'autoplay; fullscreen; picture-in-picture'
        ..allowFullscreen = true;
      return iframe;
    });
    return true;
  } else {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final videoElement = html.VideoElement()
        ..src = cleanUrl
        ..controls = true
        ..autoplay = autoPlay
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '12px'
        ..style.objectFit = 'contain'
        ..style.backgroundColor = '#000000';
      return videoElement;
    });
    return true;
  }
}

String _getYouTubeEmbedUrl(String url) {
  String videoId = '';
  if (url.contains('youtu.be/')) {
    videoId = url.split('youtu.be/').last.split('?').first;
  } else if (url.contains('v=')) {
    videoId = url.split('v=').last.split('&').first;
  } else if (url.contains('/embed/')) {
    videoId = url.split('/embed/').last.split('?').first;
  }
  return 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0';
}

String _getVimeoEmbedUrl(String url) {
  final parts = url.split('/');
  final videoId = parts.isNotEmpty ? parts.last : '';
  return 'https://player.vimeo.com/video/$videoId?autoplay=1';
}
