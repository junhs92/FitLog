class AppSpacing {
  AppSpacing._();

  // Base spacing unit: 4px
  static const double unit = 4.0;

  // Spacing scale
  static const double xs = unit; // 4px
  static const double sm = unit * 2; // 8px
  static const double md = unit * 3; // 12px
  static const double lg = unit * 4; // 16px
  static const double xl = unit * 6; // 24px
  static const double xxl = unit * 8; // 32px
  static const double xxxl = unit * 12; // 48px

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 999.0;

  // Component-specific spacing
  static const double cardPadding = lg;
  static const double screenPadding = lg;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;
}
