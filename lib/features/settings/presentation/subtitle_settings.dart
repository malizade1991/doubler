import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/subtitle_style.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_slider.dart';
import '../../../shared/widgets/subtitle_stage.dart';

class _Swatch {
  const _Swatch(this.color, this.labelKey);

  final Color color;
  final String labelKey;
}

/// Live-preview subtitle editor: size, colours and placement, all applied to a
/// real [SubtitleStage] so what you see is what the dub renders.
class SubtitleSettingsPanel extends ConsumerWidget {
  const SubtitleSettingsPanel({super.key});

  static const List<_Swatch> textSwatches = [
    _Swatch(Color(0xFFFFFFFF), 'colorWhite'),
    _Swatch(AppColors.voice, 'colorAmber'),
    _Swatch(Color(0xFF7ED4E0), 'colorTeal'),
    _Swatch(AppColors.ink, 'colorInk'),
  ];

  static const List<_Swatch> backgroundSwatches = [
    _Swatch(Color(0xCC07343C), 'colorDeepTeal'),
    _Swatch(Color(0x99000000), 'colorBlack'),
    _Swatch(Color(0x22FFFFFF), 'colorFrost'),
    _Swatch(Color(0x00000000), 'colorNone'),
  ];

  static const double minFontSize = 14;
  static const double maxFontSize = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = ref.watch(subtitleStyleProvider);
    final notifier = ref.read(subtitleStyleProvider.notifier);

    void update(SubtitleStyle next) => notifier.state = next;

    return DoublerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.subtitlePreview,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              DoublerPill(
                label: '${style.fontSize.round()} px',
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 108,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF102623),
              borderRadius: AppRadii.card,
            ),
            child: SubtitleStage(text: l10n.tagline, style: style),
          ),
          const SizedBox(height: AppSpacing.md),
          DoublerSlider(
            label: l10n.fontSize,
            icon: Icons.format_size,
            value: ((style.fontSize - minFontSize) /
                    (maxFontSize - minFontSize))
                .clamp(0, 1),
            valueLabel: '${style.fontSize.round()} px',
            onChanged: (v) =>
                update(style.copyWith(fontSize: minFontSize + v * (maxFontSize - minFontSize))),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.textColor, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final swatch in textSwatches)
                DoublerChoicePill(
                  color: swatch.color,
                  label: l10n.message(swatch.labelKey),
                  selected: style.textColor == swatch.color,
                  onSelected: () =>
                      update(style.copyWith(textColor: swatch.color)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.background, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final swatch in backgroundSwatches)
                DoublerChoicePill(
                  color: swatch.color,
                  label: l10n.message(swatch.labelKey),
                  selected: style.backgroundColor == swatch.color,
                  onSelected: () =>
                      update(style.copyWith(backgroundColor: swatch.color)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.position, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final position in SubtitlePosition.values)
                DoublerChoicePill(
                  label: _positionLabel(l10n, position),
                  selected: style.position == position,
                  onSelected: () => update(style.copyWith(position: position)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _positionLabel(
    AppLocalizations l10n,
    SubtitlePosition position,
  ) {
    return switch (position) {
      SubtitlePosition.top => l10n.positionTop,
      SubtitlePosition.center => l10n.positionCenter,
      SubtitlePosition.bottom => l10n.positionBottom,
    };
  }
}
