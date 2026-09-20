import 'package:flutter/material.dart';

abstract final class AppShadows {
  static List<BoxShadow> card(Brightness brightness) {
    final opacity = brightness == Brightness.dark ? 0.35 : 0.08;
    return [
      BoxShadow(
        color: Color.fromRGBO(7, 52, 60, opacity),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
