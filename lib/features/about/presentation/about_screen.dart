import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/audio_waveform.dart';
import '../../../shared/widgets/doubler_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            AppConstants.brandLatin,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            l10n.appName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          const AudioWaveform(active: true),
          const SizedBox(height: AppSpacing.md),
          DoublerCard(child: Text(l10n.aboutBody)),
          const SizedBox(height: AppSpacing.sm),
          DoublerCard(child: Text(l10n.offlineNote)),
          const SizedBox(height: AppSpacing.sm),
          DoublerCard(child: Text(l10n.privacyBody)),
        ],
      ),
    );
  }
}
