import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'solution_video_player_stub.dart'
    if (dart.library.html) 'solution_video_player_web.dart' as video_reg;

/// Native Reusable Solution Video Player Widget
/// Supports Direct MP4/WebM/Supabase Storage Video URLs, YouTube Embeds, and HTML5 Native Video Controls
class SolutionVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final double height;
  final bool autoPlay;
  final VoidCallback? onDelete;

  const SolutionVideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.title,
    this.height = 240,
    this.autoPlay = false,
    this.onDelete,
  }) : super(key: key);

  @override
  State<SolutionVideoPlayerWidget> createState() => _SolutionVideoPlayerWidgetState();
}

class _SolutionVideoPlayerWidgetState extends State<SolutionVideoPlayerWidget> {
  late String _viewId;
  bool _isHtmlElementRegistered = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'sol_video_${DateTime.now().microsecondsSinceEpoch}';
    _setupWebVideoPlayer();
  }

  @override
  void didUpdateWidget(covariant SolutionVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _viewId = 'sol_video_${DateTime.now().microsecondsSinceEpoch}';
      _setupWebVideoPlayer();
    }
  }

  void _setupWebVideoPlayer() {
    if (!kIsWeb || widget.videoUrl.trim().isEmpty) return;
    _isHtmlElementRegistered = video_reg.registerWebVideoView(_viewId, widget.videoUrl, widget.autoPlay);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.trim().isEmpty) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_camera_back_outlined, size: 36, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(
              'No Solution Video Uploaded',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null && widget.title!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text(
                  widget.title!,
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const Spacer(),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    tooltip: 'Remove Video',
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ),

        Container(
          width: double.infinity,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x1F0F172A), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Stack(
            children: [
              if (kIsWeb && _isHtmlElementRegistered)
                HtmlElementView(viewType: _viewId)
              else
                _buildFallbackMobilePlayer(),

              if (widget.onDelete != null && (widget.title == null || widget.title!.isEmpty))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      onPressed: widget.onDelete,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackMobilePlayer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 48,
            icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF38BDF8)),
            onPressed: () async {
              final uri = Uri.parse(widget.videoUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to Play Solution Video',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
