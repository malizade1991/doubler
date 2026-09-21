import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/language.dart';
import '../../../domain/models/language_catalog.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../../../shared/widgets/mixed_direction_text.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ui = ref.watch(localeProvider);
    final source = ref.watch(sourceLanguageCodeProvider);
    final target = ref.watch(targetLanguageCodeProvider);

    return DoublerScaffold(
      title: l10n.languageSelection,
      actions: [
        IconButton(
          tooltip: l10n.swapLanguages,
          onPressed: () {
            if (source == 'auto') {
              return;
            }
            ref.read(sourceLanguageCodeProvider.notifier).state = target;
            ref.read(targetLanguageCodeProvider.notifier).state = source;
          },
          icon: const Icon(Icons.swap_horiz),
        ),
      ],
      body: DoublerPage(
        children: [
          DoublerSectionHeader(label: l10n.uiLanguage, topGap: 0),
          Text(
            l10n.uiLanguageHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final code in LanguageCatalog.uiLanguageCodes)
                DoublerChoicePill(
                  label: LanguageCatalog.byCode(code).nativeName,
                  selected: ui.languageCode == code,
                  onSelected: () =>
                      ref.read(localeProvider.notifier).setLocale(Locale(code)),
                ),
            ],
          ),
          DoublerSectionHeader(label: l10n.sourceLanguage),
          _LanguageList(
            languages: LanguageCatalog.inputs,
            selectedCode: source,
            autoLabel: l10n.autoDetect,
            onSelect: (lang) =>
                ref.read(sourceLanguageCodeProvider.notifier).state = lang.code,
          ),
          DoublerSectionHeader(label: l10n.targetLanguage),
          _LanguageList(
            languages: LanguageCatalog.outputs,
            selectedCode: target,
            autoLabel: l10n.autoDetect,
            onSelect: (lang) =>
                ref.read(targetLanguageCodeProvider.notifier).state = lang.code,
          ),
          DoublerSectionHeader(label: l10n.mixedSampleLabel),
          DoublerCard(
            child: MixedDirectionText(
              text: l10n.mixedSample,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageList extends StatelessWidget {
  const _LanguageList({
    required this.languages,
    required this.selectedCode,
    required this.autoLabel,
    required this.onSelect,
  });

  final List<Language> languages;
  final String selectedCode;
  final String autoLabel;
  final ValueChanged<Language> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final lang in languages)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: DoublerTile(
              onTap: () => onSelect(lang),
              selected: lang.code == selectedCode,
              title: lang.code == 'auto' ? autoLabel : lang.nativeName,
              subtitle: lang.code == 'auto' ? null : lang.code,
              leading: Text(
                lang.flag,
                style: const TextStyle(fontSize: 22),
              ),
              trailing: lang.isRtl
                  ? Icon(
                      Icons.format_textdirection_r_to_l,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}
