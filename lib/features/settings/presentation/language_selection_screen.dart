import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/language.dart';
import '../../../domain/models/language_catalog.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/mixed_direction_text.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ui = ref.watch(localeProvider);
    final source = ref.watch(sourceLanguageCodeProvider);
    final target = ref.watch(targetLanguageCodeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSelection)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(l10n.uiLanguage, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final code in LanguageCatalog.uiLanguageCodes)
                ChoiceChip(
                  label: Text(code),
                  selected: ui.languageCode == code,
                  onSelected: (_) =>
                      ref.read(localeProvider.notifier).setLocale(Locale(code)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.sourceLanguage, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _LanguageList(
            languages: LanguageCatalog.inputs,
            selectedCode: source,
            autoLabel: l10n.autoDetect,
            onSelect: (lang) =>
                ref.read(sourceLanguageCodeProvider.notifier).state = lang.code,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.targetLanguage, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _LanguageList(
            languages: LanguageCatalog.outputs,
            selectedCode: target,
            autoLabel: l10n.autoDetect,
            onSelect: (lang) =>
                ref.read(targetLanguageCodeProvider.notifier).state = lang.code,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.mixedSampleLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
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
            child: DoublerCard(
              onTap: () => onSelect(lang),
              child: Row(
                children: [
                  Text(lang.flag),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      lang.code == 'auto' ? autoLabel : lang.nativeName,
                      textDirection: lang.textDirection,
                    ),
                  ),
                  if (lang.code == selectedCode)
                    Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
