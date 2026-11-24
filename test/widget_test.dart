import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moogs_phone/core/theme/tokens.dart';
import 'package:moogs_phone/core/widgets/contact_row.dart';
import 'package:moogs_phone/features/recents/recents_filter_chips.dart';
import 'package:moogs_phone/main.dart';

Future<void> _pumpDialer(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MoogsTheme.light,
      darkTheme: MoogsTheme.dark,
      home: const DialerHomePage(),
    ),
  );
  // The aurora background is intentionally animated continuously.
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('shows the four destinations with the keypad selected by default',
      (tester) async {
    await tester.pumpWidget(const MoogsPhoneApp());
    expect(find.text("Moog's Phone"), findsOneWidget);
    expect(find.text('Enter number'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Recents'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Keypad'), findsOneWidget);
  });

  testWidgets('tapping keypad digits builds the displayed number',
      (tester) async {
    await _pumpDialer(tester);

    await tester.tap(find.bySemanticsLabel('Digit 1'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Digit 2'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Digit 3'));
    await tester.pump();

    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('long-pressing zero inserts a plus sign', (tester) async {
    await _pumpDialer(tester);

    await tester.longPress(find.bySemanticsLabel('Digit 0'));
    await tester.pump();

    expect(find.text('+'), findsOneWidget);
  });

  testWidgets('long-pressing backspace clears the complete number',
      (tester) async {
    await _pumpDialer(tester);

    for (final digit in ['1', '2', '3']) {
      await tester.tap(find.bySemanticsLabel('Digit $digit'));
      await tester.pump();
    }
    expect(find.text('123'), findsOneWidget);

    await tester.longPress(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(find.text('123'), findsNothing);
    expect(find.text('Enter number'), findsOneWidget);
  });

  testWidgets('keypad keys expose spoken labels for digits, star and pound',
      (tester) async {
    await _pumpDialer(tester);
    expect(find.bySemanticsLabel('Digit 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Star'), findsOneWidget);
    expect(find.bySemanticsLabel('Pound'), findsOneWidget);
  });

  testWidgets('slide to answer invokes callback after passing 85 percent',
      (tester) async {
    var answers = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoogsTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SlideToAnswer(onAnswer: () => answers++),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byIcon(Icons.call_rounded), const Offset(230, 0));
    await tester.pump();

    expect(answers, 1);
  });

  testWidgets('short slide snaps back without answering', (tester) async {
    var answers = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoogsTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SlideToAnswer(onAnswer: () => answers++),
            ),
          ),
        ),
      ),
    );

    final handle = find.byIcon(Icons.call_rounded);
    final start = tester.getTopLeft(handle);
    await tester.drag(handle, const Offset(60, 0));
    await tester.pump();
    expect(answers, 0);

    await tester.pump(const Duration(milliseconds: 350));
    final end = tester.getTopLeft(handle);
    expect((end.dx - start.dx).abs(), lessThan(1));
    expect(answers, 0);
  });

  test('both light and dark themes provide MoogTokens', () {
    expect(MoogsTheme.light.extension<MoogTokens>(), isA<MoogTokens>());
    expect(MoogsTheme.dark.extension<MoogTokens>(), isA<MoogTokens>());
  });

  testWidgets('home remains buildable at 130 percent text scale',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoogsTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: DialerHomePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Moog's Phone"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
