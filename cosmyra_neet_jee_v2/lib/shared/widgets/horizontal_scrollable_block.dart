import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A robust horizontal scroll container for content that exceeds available viewport width,
/// such as two-column matching questions (List I & List II), wide tables, chemical structures,
/// or long mathematical equations.
///
/// Features:
/// - Bidirectional scrolling (left-to-right and right-to-left)
/// - Does not constrain child width to the viewport, allowing natural layout
/// - Detects content overflow dynamically
/// - Shows subtle visual affordance ('Scroll horizontally') only when content overflows
/// - Provides a smooth scrollbar for touch, trackpad, and mouse drag on both mobile and web
/// - Preserves vertical page scrolling
class HorizontalScrollableBlock extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showAffordance;

  const HorizontalScrollableBlock({
    super.key,
    required this.child,
    this.padding,
    this.showAffordance = true,
  });

  @override
  State<HorizontalScrollableBlock> createState() => _HorizontalScrollableBlockState();
}

class _HorizontalScrollableBlockState extends State<HorizontalScrollableBlock> {
  final ScrollController _scrollController = ScrollController();
  bool _hasOverflow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollExtent());
  }

  void _checkScrollExtent() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final hasOverflow = maxExtent > 2.0;
    if (hasOverflow != _hasOverflow) {
      setState(() {
        _hasOverflow = hasOverflow;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollExtent);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Re-check scroll extent after layout changes
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollExtent());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showAffordance && _hasOverflow)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 13, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text(
                            'Scroll horizontally',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: ScrollbarThemeData(
                    thickness: const WidgetStatePropertyAll<double>(4.0),
                    radius: const Radius.circular(4),
                    thumbColor: WidgetStatePropertyAll<Color>(const Color(0xFF94A3B8).withAlpha(150)),
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: _hasOverflow,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: widget.padding,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
