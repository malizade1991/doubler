import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'doubler_button.dart';

Future<void> showDoublerDialog({
  required BuildContext context,
  required String title,
  required String body,
  String? confirmLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          DoublerButton(
            label: confirmLabel ?? 'OK',
            expanded: false,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      );
    },
  );
}

Future<T?> showDoublerSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: AppSpacing.sheet,
        child: builder(ctx),
      );
    },
  );
}
