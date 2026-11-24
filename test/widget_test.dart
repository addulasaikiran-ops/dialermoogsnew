import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moogs_phone/core/theme/tokens.dart';
import 'package:moogs_phone/core/widgets/contact_row.dart';
import 'package:moogs_phone/core/widgets/moog_logo.dart';
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

  testWidgets('Recents filter chips expose all four local filters', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      theme: MoogsTheme.light,
      home: Scaffold(body: RecentFilterChips(
        selected: 'All',
        onSelected: (value) => selected = value,
      )),
    ));

    for (final filter in RecentFilterChips.values) {
      expect(find.text(filter), findsOneWidget);
    }
    await tester.tap(find.text('Missed'));
    expect(selected, 'Missed');
  });

  testWidgets('missed ContactRow colors only the contact name red', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: MoogsTheme.light,
      home: Scaffold(body: ContactRow(
        name: 'Rhea Patel',
        number: '9876543210',
        missed: true,
        onCall: () {},
      )),
    ));

    final tokens = MoogsTheme.light.extension<MoogTokens>()!;
    final name = tester.widget<Text>(find.text('Rhea Patel'));
    final number = tester.widget<Text>(find.text('9876543210'));
    expect(name.style?.color, tokens.missed);
    expect(number.style?.color, tokens.textMuted);
  });

  testWidgets('ContactRow call action has an accessible semantic label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: MoogsTheme.light,
      home: Scaffold(body: ContactRow(
        name: 'Rhea Patel',
        number: '9876543210',
        onCall: () {},
      )),
    ));

    expect(find.bySemanticsLabel('Call Rhea Patel'), findsOneWidget);
    semantics.dispose();
  });


  testWidgets('missed-call badge counts unseen calls and clears on Recents open',
      (tester) async {
    const channel = MethodChannel('com.moogs.phone/phone_data');
    var lastSeen = 1000;
    var permissionPrompts = 0;
    final recentRows = [
      {'name': 'Missed One', 'number': '111', 'dateMillis': 2000, 'callType': 3},
      {'name': 'Missed Two', 'number': '222', 'dateMillis': 3000, 'callType': 3},
      {'name': 'Incoming', 'number': '333', 'dateMillis': 4000, 'callType': 1},
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getReduceEffects':
          return false;
        case 'hasCallLogPermission':
          return true;
        case 'getRecentsLastSeenMillis':
          return lastSeen;
        case 'getRecents':
          return recentRows;
        case 'setRecentsLastSeenMillis':
          lastSeen = (call.arguments as Map)['millis'] as int;
          return null;
        case 'requestPermission':
          permissionPrompts++;
          return true;
        case 'getFavorites':
          return <Map<String, Object?>>[];
        default:
          return null;
      }
    });
    moogMissedCount.value = 0;

    await tester.pumpWidget(MaterialApp(
      theme: MoogsTheme.light,
      home: const DialerHomePage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('missed-call-badge')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('missed-call-badge'))).data,
      '2',
    );
    expect(permissionPrompts, 0);

    await tester.tap(find.text('Recents'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(moogMissedCount.value, 0);
    expect(find.byKey(const ValueKey('missed-call-badge')), findsNothing);
    expect(lastSeen, greaterThan(3000));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('ContactRow exposes direction labels for recent calls',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: MoogsTheme.light,
      home: Scaffold(
        body: ContactRow(
          name: 'Incoming Caller',
          number: 'Incoming Caller',
          relativeTime: '2h ago',
          callType: 1,
          onCall: () {},
        ),
      ),
    ));

    expect(find.bySemanticsLabel('Incoming call'), findsOneWidget);
    expect(find.text('Incoming Caller'), findsOneWidget);
    expect(find.text('2h ago'), findsOneWidget);
    semantics.dispose();
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
