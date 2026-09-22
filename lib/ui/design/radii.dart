import 'package:flutter/widgets.dart';

/// Shared corner-radius scale for the whole app. Everything rounded moves to
/// one of these instead of ad hoc `BorderRadius.circular(n)` literals.
abstract final class AppRadii {
  const AppRadii._();

  static const double sm = 14;
  static const double md = 20;
  static const double lg = 28;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));

  static const StadiumBorder pill = StadiumBorder();
}
