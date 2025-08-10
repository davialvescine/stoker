import 'package:flutter/material.dart';
import '../constants/dimensions.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < kMobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= kMobileBreakpoint &&
      MediaQuery.of(context).size.width < kTabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= kDesktopBreakpoint;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= kTabletBreakpoint;

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < kMobileBreakpoint) return 2;
    if (width < kTabletBreakpoint) return 3;
    if (width < kDesktopBreakpoint) return 4;
    return 4;
  }

  static double getMaxFormWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    return 600;
  }
}
