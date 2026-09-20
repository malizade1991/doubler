import 'package:doubler/shared/widgets/audio_waveform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('waveform is accessible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AudioWaveform(active: true)),
      ),
    );
    expect(find.bySemanticsLabel('waveform'), findsOneWidget);
  });
}
