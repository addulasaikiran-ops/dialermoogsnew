import 'package:flutter_test/flutter_test.dart';
import 'package:moogs_phone/main.dart';

void main() {
  testWidgets('shows Moog\'s Phone keypad foundation', (tester) async {
    await tester.pumpWidget(const MoogsPhoneApp());
    expect(find.text("Moog's Phone"), findsOneWidget);
    expect(find.text('Enter a number'), findsOneWidget);
    expect(find.text('FAVORITES     RECENTS     CONTACTS     KEYPAD'), findsOneWidget);
  });

  testWidgets('keypad appends digits to the number display', (tester) async {
    await tester.pumpWidget(const MoogsPhoneApp());
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text('1'), findsNWidgets(2));
  });
}
