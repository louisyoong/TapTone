import 'package:taptone/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows color assist controls and filters', (tester) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ColorAssistApp());

    expect(find.text('TapTone'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Upload Photo'), findsOneWidget);
    expect(find.text('Deuteranomaly'), findsOneWidget);
    expect(find.text('Protanopia'), findsOneWidget);
    expect(find.text('Tritanopia'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(
      find.textContaining('cannot restore normal color vision'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.image_search_rounded), findsOneWidget);
  });
}
