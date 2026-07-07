import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Responsive {
  static double _w(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isTablet(BuildContext context) => _w(context) >= 600;
  static bool isSmallPhone(BuildContext context) => _w(context) < 360;

  /// Stepped horizontal page padding — grows on wider screens.
  static double hPad(BuildContext context) {
    final w = _w(context);
    if (w >= 768) return 48.w;
    if (w >= 600) return 36.w;
    if (w < 360) return 16.w;
    return 24.w;
  }

  /// Vertical page padding.
  static double vPad(BuildContext context) => isTablet(context) ? 32.h : 24.h;

  /// Avatar / icon container size — screenutil-scaled.
  static double avatar(BuildContext context, double base) => base.r;

  /// App-icon size for auth pages.
  static double logoSize(BuildContext context) {
    if (isTablet(context)) return 120.r;
    if (isSmallPhone(context)) return 72.r;
    return 88.r;
  }
}

extension ResponsiveContext on BuildContext {
  bool get isTablet => Responsive.isTablet(this);
  bool get isSmallPhone => Responsive.isSmallPhone(this);
  double get hPad => Responsive.hPad(this);
  double get vPad => Responsive.vPad(this);
  double get logoSize => Responsive.logoSize(this);
  double rAvatar(double base) => Responsive.avatar(this, base);
  /// Convenience passthrough — prefer .sp directly on numbers in widget code.
  double rScale(double size) => size.sp;
}

/// Centres content with a max width on tablets.
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  const ResponsivePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.hPad,
        vertical: context.vPad,
      ),
      child: child,
    );

    if (context.isTablet) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: content,
        ),
      );
    }

    return content;
  }
}
