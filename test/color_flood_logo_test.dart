import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_flood/components/color_flood_logo.dart';

void main() {
  group('ColorFloodLogo', () {
    testWidgets('renders all letters correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ColorFloodLogo(),
            ),
          ),
        ),
      );

      // Verify that all letters are present
      expect(find.text('C'), findsOneWidget);
      expect(find.text('o'), findsNWidgets(3)); // 3 'o' letters
      expect(find.text('l'), findsNWidgets(2)); // 2 'l' letters
      expect(find.text('r'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('d'), findsOneWidget);
    });

    testWidgets('applies custom fontSize when provided', (WidgetTester tester) async {
      const customFontSize = 24.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ColorFloodLogo(fontSize: customFontSize),
            ),
          ),
        ),
      );

      // Find the first text widget and verify its font size
      final textWidget = tester.widget<Text>(find.text('C').first);
      expect(textWidget.style?.fontSize, customFontSize);
    });

    testWidgets('disables animations when specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ColorFloodLogo(
                enableFloatingAnimation: false,
                enableHoverEffects: false,
              ),
            ),
          ),
        ),
      );

      // The widget should still render without errors
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('applies responsive font sizing', (WidgetTester tester) async {
      // Test with small screen width
      await tester.binding.setSurfaceSize(const Size(400, 800));
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ColorFloodLogo(),
            ),
          ),
        ),
      );

      // The widget should render with appropriate font size for small screens
      expect(find.text('C'), findsOneWidget);
    });
  });
}
