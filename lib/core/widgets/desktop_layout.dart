import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'sidebar_navigation.dart';
import 'header_bar.dart';

class DesktopLayout extends StatelessWidget {
  final String currentRoute;
  final String title;
  final String? subtitle;
  final List<Widget>? headerActions;
  final Widget child;

  const DesktopLayout({
    super.key,
    required this.currentRoute,
    required this.title,
    this.subtitle,
    this.headerActions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed Desktop Sidebar
          SidebarNavigation(currentRoute: currentRoute),

          // Main Workspace Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeaderBar(
                  title: title,
                  subtitle: subtitle,
                  actions: headerActions,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
