import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../infrastructure/gemini/gemini_config.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_dialogs.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../../../shared/widgets/doubler_text_field.dart';
import '../application/api_key_controller.dart';
import '../domain/api_key_validator.dart';

/// BYOK key entry. The whole point of this screen is that a *valid* key is
/// never rejected: input is sanitised (spaces, quotes, `key=` prefixes, zero
/// width marks), both Google key formats are accepted, and only Google's own
/// answer can call a key invalid.
class ApiKeySetupScreen extends ConsumerStatefulWidget {
  const ApiKeySetupScreen({super.key});

  @override
  ConsumerState<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends ConsumerState<ApiKeySetupScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final raw = _controller.text;
    final next = raw.trim().isEmpty
        ? null
        : (ApiKeyValidator.validate(raw).isValid
            ? null
            : ApiKeyValidator.validate(raw).code);
    if (next != _localError) {
      setState(() => _localError = next);
    }
  }

  Future<void> _save(String raw) async {
    final l10n = AppLocalizations.of(context);
    final result =
        await ref.read(apiKeyControllerProvider.notifier).save(raw);
    if (!mounted) {
      return;
    }
    if (result == ApiKeySaveResult.saved) {
      _controller.clear();
      showDoublerToast(context, l10n.keySaved);
      return;
    }
    // The field keeps the text so the user can fix it; only the reason shows.
    unawaited(HapticFeedback.vibrate());
    setState(() {});
  }

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    final code =
        await ref.read(apiKeyControllerProvider.notifier).testConnection();
    if (!mounted) {
      return;
    }
    if (code == null) {
      showDoublerToast(context, l10n.connectionOk);
    } else {
      showDoublerToast(context, l10n.message(code), error: true);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDoublerConfirm(
      context: context,
      title: l10n.deleteKey,
      body: l10n.confirmDeleteKeyBody,
      confirmLabel: l10n.deleteKey,
      cancelLabel: l10n.cancel,
    );
    if (!ok || !mounted) {
      return;
    }
    await ref.read(apiKeyControllerProvider.notifier).delete();
    if (!mounted) {
      return;
    }
    showDoublerToast(context, l10n.keyDeleted);
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(
      const ClipboardData(text: GeminiConfig.keyConsoleUrl),
    );
    if (!mounted) {
      return;
    }
    showDoublerToast(context, AppLocalizations.of(context).copied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(apiKeyControllerProvider);
    final data = async.valueOrNull;
    final typed = _controller.text;
    final typedCheck =
        typed.trim().isEmpty ? null : ApiKeyValidator.validate(typed);
    final hasStoredKey = data?.hasKey ?? false;

    return DoublerScaffold(
      title: l10n.apiKeySetup,
      actions: [
        IconButton(
          tooltip: l10n.help,
          icon: const Icon(Icons.help_outline),
          onPressed: () => showDoublerDialog(
            context: context,
            title: l10n.apiKeySetup,
            body: l10n.byokExplainer,
          ),
        ),
      ],
      body: DoublerPage(
        children: [
          _KeyStatusCard(
            hasKey: hasStoredKey,
            masked: data?.masked,
            kind: data?.kind,
          ),
          const SizedBox(height: AppSpacing.md),
          DoublerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.keyHowToTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _StepRow(index: 1, text: l10n.keyStepOne),
                _StepRow(index: 2, text: l10n.keyStepTwo),
                _StepRow(index: 3, text: l10n.keyStepThree),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        GeminiConfig.keyConsoleUrl,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _copyUrl,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(l10n.copy),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DoublerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DoublerTextField(
                  controller: _controller,
                  label: l10n.apiKeySetup,
                  hint: l10n.keyHint,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  errorText: _localError == null
                      ? null
                      : l10n.message(_localError),
                  helperText: typedCheck != null && typedCheck.isValid
                      ? (typedCheck.isAuthKey ? l10n.keyKindAuth : l10n.keyKindAny)
                      : l10n.keyPasteNote,
                  onSubmitted: _save,
                  suffix: IconButton(
                    tooltip: _obscure ? l10n.showKey : l10n.hideKey,
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                DoublerFieldToolbar(
                  children: [
                    DoublerPasteButton(
                      tooltip: l10n.paste,
                      onPaste: (text) => _controller.text =
                          ApiKeyValidator.sanitize(text),
                    ),
                    if (typed.isNotEmpty)
                      TextButton.icon(
                        onPressed: _controller.clear,
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(l10n.clearField),
                      ),
                  ],
                ),
                if (typedCheck != null && !typedCheck.isValid) ...[
                  const SizedBox(height: AppSpacing.sm),
                  DoublerStatusBanner(
                    mood: DoublerMood.warning,
                    message: l10n.message(typedCheck.code),
                  ),
                ],
              ],
            ),
          ),
          if (data != null && data.warningCode != null) ...[
            const SizedBox(height: AppSpacing.md),
            DoublerStatusBanner(
              mood: DoublerMood.warning,
              message: l10n.message(data.warningCode),
            ),
          ],
          if (data != null &&
              data.messageCode != null &&
              data.messageCode != 'keySaved' &&
              data.messageCode != 'keyDeleted') ...[
            const SizedBox(height: AppSpacing.md),
            DoublerStatusBanner(
              mood: data.messageCode == 'connectionOk'
                  ? DoublerMood.success
                  : DoublerMood.error,
              message: l10n.message(data.messageCode),
              action: data.busy
                  ? null
                  : DoublerButton(
                      label: l10n.tryAgain,
                      expanded: false,
                      variant: DoublerButtonVariant.ghost,
                      onPressed: _test,
                    ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          DoublerStatusBanner(
            icon: Icons.shield_outlined,
            message: l10n.keyNeverLeaves,
          ),
        ],
      ),
      bottomBar: DoublerActionRow(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DoublerButton(
                  label: l10n.saveKey,
                  icon: Icons.save_outlined,
                  onPressed: () => _save(_controller.text),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: DoublerButton(
                  label: l10n.testConnection,
                  variant: DoublerButtonVariant.secondary,
                  icon: Icons.wifi_tethering,
                  busy: data?.busy ?? false,
                  onPressed: hasStoredKey ? _test : null,
                ),
              ),
            ],
          ),
          if (hasStoredKey) ...[
            const SizedBox(height: AppSpacing.xs),
            DoublerButton(
              label: l10n.deleteKey,
              variant: DoublerButtonVariant.destructive,
              icon: Icons.delete_outline,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

class _KeyStatusCard extends StatelessWidget {
  const _KeyStatusCard({
    required this.hasKey,
    required this.masked,
    required this.kind,
  });

  final bool hasKey;
  final String? masked;
  final ApiKeyKind? kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return DoublerCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: (hasKey ? AppColors.success : AppColors.warning)
                .withValues(alpha: 0.16),
            child: Icon(
              hasKey ? Icons.check : Icons.key_outlined,
              color: hasKey ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasKey ? l10n.keyStatusConfigured : l10n.keyStatusMissing,
                  style: theme.textTheme.titleMedium,
                ),
                if (masked != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    masked!,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (hasKey && kind == ApiKeyKind.standardKey) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.keyWarningLegacy,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.warning),
                  ),
                ],
              ],
            ),
          ),
          if (hasKey)
            DoublerPill(
              label: kind == ApiKeyKind.authKey ? 'Auth' : 'API',
              icon: Icons.verified_user_outlined,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
