import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Lightweight decorative waveform. Not a real FFT — cheap to paint.
class AudioWaveform extends StatelessWidget {
  const AudioWaveform({
    super.key,
    this.active = false,
    this.height = 48,
  });

  final bool active;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'waveform',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _WavePainter(
            color: Theme.of(context).colorScheme.primary,
            accent: AppColors.voice,
            active: active,
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.color,
    required this.accent,
    required this.active,
  });

  final Color color;
  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? accent : color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const bars = 24;
    final mid = size.height / 2;
    for (var i = 0; i < bars; i++) {
      final t = i / bars;
      final mag = active ? (0.35 + 0.65 * (sin(t * pi * 4).abs())) : 0.25;
      final h = size.height * mag * 0.5;
      final x = (i + 0.5) * (size.width / bars);
      canvas.drawLine(Offset(x, mid - h), Offset(x, mid + h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.color != color;
}
