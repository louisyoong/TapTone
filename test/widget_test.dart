import 'package:taptone/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('formats detected colors with their full RGB hex value', () {
    expect(DetectedColor.fromColor(const Color(0xFFE53935)).hex, '#E53935');
  });

  testWidgets('shows onboarding once and remembers completion', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ColorAssistApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Helping colorblind users distinguish colors better.'),
      findsOneWidget,
    );
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Assist'), findsNothing);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Assist'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(OnboardingGate.completedPreferenceKey), isTrue);
  });

  testWidgets('shows color assist controls and filters', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnboardingGate.completedPreferenceKey: true,
    });
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ColorAssistApp());
    await tester.pumpAndSettle();

    expect(find.text('TapTone'), findsOneWidget);
    expect(find.text('Assist'), findsOneWidget);
    expect(find.text('Detect'), findsOneWidget);
    expect(find.text('Simulate'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Upload Photo'), findsOneWidget);
    expect(find.text('Deuteranomaly'), findsOneWidget);
    expect(find.text('Protanopia'), findsOneWidget);
    expect(find.text('Tritanopia'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.byIcon(Icons.image_search_rounded), findsOneWidget);
  });

  testWidgets('shows settings and persists dark mode', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnboardingGate.completedPreferenceKey: true,
    });

    await tester.pumpWidget(const ColorAssistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('App Name'), findsOneWidget);
    expect(find.text('TapTone'), findsWidgets);
    expect(find.text('App Version'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(ColorAssistApp.themeModePreferenceKey), isTrue);
  });
}
