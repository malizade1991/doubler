import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Minimum clearance that keeps tappable widgets out of the notch, the
  /// Android navigation bar and the iOS home indicator.
  static const double minInset = md;

  /// Height of the pinned action bar on the live screen (excluding insets).
  static const double barHeight = 72;

  static const EdgeInsets page = EdgeInsets.all(lg);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(lg, sm, lg, lg);
  static const EdgeInsets snackBar = EdgeInsets.fromLTRB(md, xs, md, md);
  static const EdgeInsets dialogInset = EdgeInsets.all(lg);
  static const EdgeInsets barPadding = EdgeInsets.fromLTRB(md, xs, md, xs);

  /// Scrollable padding: honours the system insets on every edge, so the last
  /// row can be scrolled out from under the navigation bar.
  static EdgeInsets pageScrollable(BuildContext context) {
    final view = MediaQuery.of(context).viewPadding;
    return EdgeInsets.fromLTRB(
      lg,
      lg,
      lg,
      (view.bottom > 0 ? view.bottom : lg) + lg,
    );
  }

  /// Padding for a pinned bottom bar: clears the system navigation bar / home
  /// indicator. The keyboard is already handled by `Scaffold`'s
  /// `resizeToAvoidBottomInset`, so `viewInsets` must not be added here.
  static EdgeInsets barInsets(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return EdgeInsets.fromLTRB(md, xs, md, xs + (bottom > minInset ? bottom : minInset));
  }
}
