import 'package:doubler/domain/models/subtitle_style.dart';
import 'package:doubler/shared/widgets/subtitle_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('subtitle stage uses font size color and mixed text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SubtitleStage(
            text: 'فارسی + English',
            style: SubtitleStyle(
              fontSize: 28,
              textColor: Color(0xFFE8A838),
              position: SubtitlePosition.top,
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('فارسی + English'));
    expect(text.style?.fontSize, 28);
    expect(text.style?.color, const Color(0xFFE8A838));
    expect(find.byType(Align), findsWidgets);
  });
}
