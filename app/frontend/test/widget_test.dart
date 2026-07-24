import 'package:flutter_test/flutter_test.dart';
import 'package:sipsara_app/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SipsaraApp());
    // Verify the app starts with the splash screen
    expect(find.text('Sipsara'), findsOneWidget);
  });
}
