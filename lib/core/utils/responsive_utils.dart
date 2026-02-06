import 'package:flutter/material.dart';

/// Responsive breakpoints following Material Design guidelines
/// with support for mobile, tablet, and desktop layouts.
class ResponsiveBreakpoints {
  // Private constructor to prevent instantiation
  ResponsiveBreakpoints._();

  /// Mobile breakpoint (< 600dp)
  static const double mobile = 600;

  /// Tablet breakpoint (600dp - 900dp)
  static const double tablet = 900;

  /// Desktop breakpoint (> 900dp)
  static const double desktop = 1200;

  /// Master-detail sidebar width for tablets
  static const double masterPanelWidth = 320;

  /// Extended master panel width for desktops
  static const double masterPanelWidthExpanded = 380;

  /// NavigationRail width when collapsed
  static const double railWidth = 72;

  /// NavigationRail width when extended (with labels)
  static const double railExtendedWidth = 180;

  /// Check if current screen is mobile size
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  /// Check if current screen is tablet size or larger
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobile;

  /// Check if current screen is desktop size
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// Get the appropriate master panel width based on screen size
  static double getMasterPanelWidth(BuildContext context) {
    if (isDesktop(context)) {
      return masterPanelWidthExpanded;
    }
    return masterPanelWidth;
  }

  /// Check if NavigationRail should be extended (show labels)
  static bool shouldExtendRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}

/// Responsive layout builder widget that automatically switches
/// between mobile and tablet/desktop layouts.
class AdaptiveLayout extends StatelessWidget {
  /// Layout for mobile screens (< 600dp)
  final Widget mobileLayout;

  /// Layout for tablet/desktop screens (>= 600dp)
  final Widget tabletLayout;

  /// Optional layout for desktop screens (>= 1200dp)
  /// If not provided, tabletLayout is used
  final Widget? desktopLayout;

  const AdaptiveLayout({
    super.key,
    required this.mobileLayout,
    required this.tabletLayout,
    this.desktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktop &&
            desktopLayout != null) {
          return desktopLayout!;
        }
        if (constraints.maxWidth >= ResponsiveBreakpoints.mobile) {
          return tabletLayout;
        }
        return mobileLayout;
      },
    );
  }
}

/// Animation durations for responsive transitions (Apple-style)
class ResponsiveAnimations {
  ResponsiveAnimations._();

  /// Duration for navigation transitions (rail slide in/out)
  static const Duration navTransition = Duration(milliseconds: 300);

  /// Duration for content crossfade transitions
  static const Duration contentFade = Duration(milliseconds: 200);

  /// Duration for panel resize animations
  static const Duration panelResize = Duration(milliseconds: 300);

  /// Duration for selection feedback
  static const Duration selectionFeedback = Duration(milliseconds: 150);

  /// Spring curve for fluid animations (iOS-style)
  static const Curve springCurve = Curves.easeOutCubic;

  /// Ease curve for fade transitions
  static const Curve fadeCurve = Curves.easeInOut;

  /// Quick curve for selection feedback
  static const Curve selectionCurve = Curves.easeOut;
}
