import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_text_field.dart';
import '../application/api_key_controller.dart';

class ApiKeySetupScreen extends ConsumerStatefulWidget {
  const ApiKeySetupScreen({super.key});

  @override
  ConsumerState<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends ConsumerState<ApiKeySetupScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(apiKeyControllerProvider);
    final data = async.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.apiKeySetup)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          DoublerCard(child: Text(l10n.byokExplainer)),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.officialKeyUrl, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          DoublerTextField(
            controller: _controller,
            label: l10n.apiKeySetup,
            hint: l10n.keyHint,
            obscureText: _obscure,
            textDirection: TextDirection.ltr,
            suffix: IconButton(
              tooltip: _obscure ? l10n.showKey : l10n.hideKey,
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          if (data?.masked != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(data!.masked!, textDirection: TextDirection.ltr),
          ],
          if (data?.messageCode != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.message(data!.messageCode)),
          ],
          const SizedBox(height: AppSpacing.lg),
          DoublerButton(
            label: l10n.saveKey,
            onPressed: () async {
              await ref.read(apiKeyControllerProvider.notifier).save(_controller.text);
              _controller.clear();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DoublerButton(
            label: l10n.testConnection,
            variant: DoublerButtonVariant.secondary,
            onPressed: data?.busy == true
                ? null
                : () => ref.read(apiKeyControllerProvider.notifier).testConnection(),
          ),
          const SizedBox(height: AppSpacing.sm),
          DoublerButton(
            label: l10n.deleteKey,
            variant: DoublerButtonVariant.ghost,
            onPressed: () => ref.read(apiKeyControllerProvider.notifier).delete(),
          ),
          const SizedBox(height: AppSpacing.lg),
          DoublerButton(
            label: l10n.appNameLatin,
            variant: DoublerButtonVariant.secondary,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
