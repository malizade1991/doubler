import 'package:flutter/material.dart';

abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
  static const BorderRadius input = BorderRadius.all(Radius.circular(sm));
}
