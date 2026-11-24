import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moogs_phone/main.dart';

void main() {
  testWidgets('shows Moog\'s Phone with four working navigation destinations', (tester) async {
    await tester.pumpWidget(const MoogsPhoneApp());
    expect(find.text("Moog's Phone"), findsOneWidget);
    expect(find.text('Enter number'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Recents'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Keypad'), findsOneWidget);
  });

  testWidgets('keypad appends digits to the number display', (tester) async {
    await tester.pumpWidget(const MoogsPhoneApp());
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text('1'), findsNWidgets(2));
  });
  testWidgets('keypad keys expose spoken labels for digits, star and pound', (tester) async {
    await tester.pumpWidget(const MoogsPhoneApp());
    expect(find.bySemanticsLabel('Digit 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Star'), findsOneWidget);
    expect(find.bySemanticsLabel('Pound'), findsOneWidget);
  });

  testWidgets('home remains buildable at 130 percent text scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoogsTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: const DialerHomePage(),
        ),
      ),
    );
    // AuroraBackdrop intentionally animates continuously; one frame is enough
    // to verify layout without waiting for an animation that never settles.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Moog's Phone"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
