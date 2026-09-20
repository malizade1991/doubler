import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/subtitle_style.dart';
import '../../../shared/widgets/doubler_slider.dart';
import '../../../shared/widgets/subtitle_stage.dart';

class SubtitleSettingsPanel extends ConsumerWidget {
  const SubtitleSettingsPanel({super.key});

  static const _textColors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFE8A838),
    Color(0xFF7ED4E0),
  ];

  static const _bgColors = <Color>[
    Color(0xCC07343C),
    Color(0x99000000),
    Color(0x00000000),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(subtitleStyleProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.subtitles, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 88,
          child: SubtitleStage(text: l10n.tagline, style: style),
        ),
        DoublerSlider(
          label: l10n.fontSize,
          value: ((style.fontSize - 14) / 26).clamp(0, 1),
          onChanged: (v) {
            ref.read(subtitleStyleProvider.notifier).state =
                style.copyWith(fontSize: 14 + v * 26);
          },
        ),
        Text(l10n.textColor, style: Theme.of(context).textTheme.labelMedium),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final color in _textColors)
              ChoiceChip(
                selected: style.textColor == color,
                label: const SizedBox(width: 16, height: 16),
                avatar: CircleAvatar(backgroundColor: color),
                onSelected: (_) => ref
                    .read(subtitleStyleProvider.notifier)
                    .state = style.copyWith(textColor: color),
              ),
          ],
        ),
        Text(l10n.background, style: Theme.of(context).textTheme.labelMedium),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final color in _bgColors)
              ChoiceChip(
                selected: style.backgroundColor == color,
                label: const SizedBox(width: 16, height: 16),
                onSelected: (_) => ref
                    .read(subtitleStyleProvider.notifier)
                    .state = style.copyWith(backgroundColor: color),
              ),
          ],
        ),
        Text(l10n.position, style: Theme.of(context).textTheme.labelMedium),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: Text(l10n.positionTop),
              selected: style.position == SubtitlePosition.top,
              onSelected: (_) => ref.read(subtitleStyleProvider.notifier).state =
                  style.copyWith(position: SubtitlePosition.top),
            ),
            ChoiceChip(
              label: Text(l10n.positionCenter),
              selected: style.position == SubtitlePosition.center,
              onSelected: (_) => ref.read(subtitleStyleProvider.notifier).state =
                  style.copyWith(position: SubtitlePosition.center),
            ),
            ChoiceChip(
              label: Text(l10n.positionBottom),
              selected: style.position == SubtitlePosition.bottom,
              onSelected: (_) => ref.read(subtitleStyleProvider.notifier).state =
                  style.copyWith(position: SubtitlePosition.bottom),
            ),
          ],
        ),
      ],
    );
  }
}
