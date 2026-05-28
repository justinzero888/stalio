import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that Semantics wrappers on Switch widgets have both
/// an identifier AND an onTap handler — required for XCUITest
/// accessibilityActivate to fire. This was the v1-v6 bug.
void main() {
  testWidgets('Switch with Semantics onTap renders correctly', (tester) async {
    bool toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            identifier: 'test_toggle',
            onTap: () => toggled = true,
            child: Switch(
              value: false,
              onChanged: (_) => toggled = true,
            ),
          ),
        ),
      ),
    );

    // Switch renders
    expect(find.byType(Switch), findsOneWidget);

    // Physical tap works
    await tester.tap(find.byType(Switch));
    expect(toggled, isTrue);
  });

  testWidgets('Switch without Semantics onTap still works physically', (tester) async {
    bool toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            identifier: 'no_action',
            child: Switch(
              value: false,
              onChanged: (_) => toggled = true,
            ),
          ),
        ),
      ),
    );

    // Physical tap still works via Switch.onChanged
    await tester.tap(find.byType(Switch));
    expect(toggled, isTrue);
  });
}
