import 'package:responsive_framework/responsive_framework.dart';

abstract final class AppBreakpoints {
  static const double mobileSmall = 320;
  static const double mobile = 390;
  static const double mobileLarge = 600;
  static const double tablet = 900;
  static const double desktop = 1440;

  static const List<Breakpoint> breakpoints = [
    Breakpoint(start: 0, end: 390, name: MOBILE),
    Breakpoint(start: 391, end: 600, name: 'MOBILE_LARGE'),
    Breakpoint(start: 601, end: 900, name: TABLET),
    Breakpoint(start: 901, end: 1440, name: DESKTOP),
    Breakpoint(start: 1441, end: 2560, name: 'DESKTOP_WIDE'),
  ];
}
