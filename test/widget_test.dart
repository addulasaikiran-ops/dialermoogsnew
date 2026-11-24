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
}
