import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../infrastructure/gemini/gemini_config.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_dialogs.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../application/api_key_controller.dart';

/// Engine settings for the BYOK connection: which Live model is used, which
/// voice speaks, and whether the stored key still authenticates.
class GeminiConfigScreen extends ConsumerWidget {
  const GeminiConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final keyState = ref.watch(apiKeyControllerProvider).valueOrNull;
    final model = ref.watch(geminiModelProvider);
    final voice = ref.watch(voiceIdProvider);
    final hasKey = keyState?.hasKey ?? false;

    return DoublerScaffold(
      title: l10n.geminiConfig,
      body: DoublerPage(
        children: [
          DoublerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.apiKeySetup,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    DoublerPill(
                      label: hasKey ? l10n.keyStatusConfigured : l10n.keyStatusMissing,
                      icon: hasKey ? Icons.check : Icons.error_outline,
                      color: hasKey ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                if (keyState?.masked != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    keyState!.masked!,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: DoublerButton(
                        label: l10n.testConnection,
                        icon: Icons.wifi_tethering,
                        busy: keyState?.busy ?? false,
                        onPressed: hasKey
                            ? () => ref
                                .read(apiKeyControllerProvider.notifier)
                                .testConnection()
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DoublerButton(
                      label: l10n.saveKey,
                      variant: DoublerButtonVariant.secondary,
                      expanded: false,
                      onPressed: () => context.push(AppRoutes.apiKeySetup),
                    ),
                  ],
                ),
                if (keyState?.messageCode != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  DoublerStatusBanner(
                    mood: keyState!.messageCode == 'connectionOk'
                        ? DoublerMood.success
                        : DoublerMood.error,
                    message: l10n.message(keyState.messageCode),
                  ),
                ],
              ],
            ),
          ),
          DoublerSectionHeader(label: l10n.modelLabel),
          for (final option in GeminiConfig.liveModels)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: DoublerTile(
                title: option.label,
                subtitle: option.note == null
                    ? option.id
                    : '${option.id} · ${option.note}',
                icon: option.id == GeminiConfig.liveModel
                    ? Icons.bolt
                    : Icons.outlined_flag,
                selected: option.id == model,
                onTap: () =>
                    ref.read(geminiModelProvider.notifier).state = option.id,
              ),
            ),
          DoublerSectionHeader(label: l10n.voice),
          DoublerCard(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final id in geminiVoices)
                  DoublerChoicePill(
                    label: id,
                    selected: id == voice,
                    onSelected: () =>
                        ref.read(voiceIdProvider.notifier).state = id,
                  ),
              ],
            ),
          ),
          DoublerSectionHeader(label: l10n.connectionLabel),
          DoublerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ConfigLine(
                  label: l10n.endpointLabel,
                  value: GeminiConfig.redactedUri(),
                ),
                _ConfigLine(
                  label: l10n.authHeaderLabel,
                  value: GeminiConfig.apiKeyHeader,
                ),
                _ConfigLine(
                  label: l10n.keyConsoleLabel,
                  value: GeminiConfig.keyConsoleUrl,
                  copyable: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.geminiConfigNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigLine extends StatelessWidget {
  const _ConfigLine({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              tooltip: AppLocalizations.of(context).copy,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (!context.mounted) {
                  return;
                }
                showDoublerToast(context, AppLocalizations.of(context).copied);
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}
