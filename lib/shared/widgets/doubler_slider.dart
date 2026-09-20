import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class DoublerSlider extends StatelessWidget {
  const DoublerSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
            Text('${(value * 100).round()}%'),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Slider(
          value: value.clamp(0, 1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
