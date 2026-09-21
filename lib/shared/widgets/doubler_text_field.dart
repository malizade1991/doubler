import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_spacing.dart';

/// Text field tuned for pasted tokens/URLs: no autocorrect, no suggestions,
/// visible-password keyboard, a built-in paste/clear affordance and inline
/// error + helper text (so the message sits next to the field, not at the
/// bottom of the screen).
class DoublerTextField extends StatelessWidget {
  const DoublerTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textDirection,
    this.errorText,
    this.helperText,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
    this.textInputAction,
    this.trailing,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final Widget? suffix;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final String? errorText;
  final String? helperText;
  final bool autofocus;
  final bool enabled;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      maxLines: maxLines,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      textDirection: textDirection,
      inputFormatters: inputFormatters,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontFamilyFallback: const <String>['monospace', 'Roboto Mono'],
        letterSpacing: 0.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        helperText: helperText,
        alignLabelWithHint: true,
        suffixIcon: suffix == null && trailing == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null) trailing!,
                  if (suffix != null) suffix!,
                ],
              ),
      ),
    );
  }
}

/// Paste button for secret fields: reads the clipboard, hands the raw string to
/// [onPaste] (which sanitises it) and gives haptic + visual feedback.
class DoublerPasteButton extends StatelessWidget {
  const DoublerPasteButton({
    super.key,
    required this.tooltip,
    required this.onPaste,
  });

  final String tooltip;
  final ValueChanged<String> onPaste;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text;
        if (text == null || text.trim().isEmpty) {
          return;
        }
        onPaste(text);
      },
      icon: const Icon(Icons.content_paste_go_outlined, size: 20),
    );
  }
}

/// Row of quick actions under a field (clear / paste / show).
class DoublerFieldToolbar extends StatelessWidget {
  const DoublerFieldToolbar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Wrap(spacing: AppSpacing.xs, children: children),
    );
  }
}
