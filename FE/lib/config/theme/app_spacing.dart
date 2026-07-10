class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double cardRadius = 20;
  static const double buttonRadius = 14;
  static const double bottomSheetRadius = 28;
  static const double inputRadius = 14;
  static const double chipRadius = 24;

  // Additive (docs/design-tokens-v2.md changelog) — micro-badge/tag pills
  // (product_card's SALE badge, brand pill, size tags) are too small for
  // chipRadius; no v1 constant fit them either.
  static const double microRadius = 4;
}
