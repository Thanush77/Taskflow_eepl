import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Grid configurations
  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  // Responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  // Card aspect ratio
  static double getCardAspectRatio(BuildContext context) {
    if (isMobile(context)) return 2.5;
    if (isTablet(context)) return 1.8;
    return 1.6;
  }

  // Dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth * 0.9;
    } else if (isTablet(context)) {
      return screenWidth * 0.7;
    } else {
      return 600; // Fixed width for desktop
    }
  }

  // Sidebar width for tablet/desktop layouts
  static double getSidebarWidth(BuildContext context) {
    if (isDesktop(context)) return 280;
    if (isTablet(context)) return 240;
    return 0; // No sidebar on mobile
  }
}

// Responsive widget wrapper
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (ResponsiveUtils.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}