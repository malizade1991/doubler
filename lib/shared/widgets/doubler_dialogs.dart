import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'doubler_button.dart';

/// Plain acknowledgement dialog.
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
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(confirmLabel ?? MaterialLocalizations.of(ctx)
                .okButtonLabel),
          ),
        ],
      );
    },
  );
}

/// Confirmation for anything destructive. Returns `true` only when the user
/// explicitly confirms.
Future<bool> showDoublerConfirm({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          DoublerButton(
            label: confirmLabel,
            variant: DoublerButtonVariant.destructive,
            expanded: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Bottom sheet that respects the notch, the home indicator and the keyboard.
Future<T?> showDoublerSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      final insets = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg + insets,
        ),
        child: Builder(builder: builder),
      );
    },
  );
}

/// Snackbar that never hides behind the navigation bar and always gives
/// tactile feedback.
void showDoublerToast(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : null,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: MaterialLocalizations.of(context).closeButtonLabel,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
}
