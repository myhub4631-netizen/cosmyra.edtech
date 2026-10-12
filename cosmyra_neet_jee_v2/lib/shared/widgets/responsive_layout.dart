import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'app_sidebar.dart';
import 'app_header.dart';

class ResponsiveLayoutShell extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget body;
  final String activeExam;
  final ValueChanged<String>? onExamChanged;
  final UserProfileModel? userProfile;

  const ResponsiveLayoutShell({
    Key? key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    required this.body,
    this.activeExam = 'NEET',
    this.onExamChanged,
    this.userProfile,
  }) : super(key: key);

  @override
  State<ResponsiveLayoutShell> createState() => _ResponsiveLayoutShellState();
}

class _ResponsiveLayoutShellState extends State<ResponsiveLayoutShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 992;

    if (isDesktop) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // Persistent Desktop Sidebar
            AppSidebar(
              selectedIndex: widget.selectedIndex,
              onItemSelected: widget.onDestinationSelected,
            ),
            // Right Main Content + Top Header
            Expanded(
              child: Column(
                children: [
                  AppHeader(
                    userProfile: widget.userProfile,
                    activeExam: widget.activeExam,
                    onOpenDrawer: () {
                      if (_scaffoldKey.currentState?.hasDrawer ?? false) {
                        _scaffoldKey.currentState?.openDrawer();
                      }
                    },
                  ),
                  Expanded(
                    child: widget.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile & Tablet Slide-Over Layout
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: Drawer(
        child: AppSidebar(
          selectedIndex: widget.selectedIndex,
          onItemSelected: widget.onDestinationSelected,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              userProfile: widget.userProfile,
              activeExam: widget.activeExam,
              onOpenDrawer: () {
                if (_scaffoldKey.currentState?.hasDrawer ?? false) {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
            ),
            Expanded(
              child: widget.body,
            ),
          ],
        ),
      ),
    );
  }
}

