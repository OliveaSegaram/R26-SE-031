import 'package:flutter_test/flutter_test.dart';
import 'package:adapted_mind_app/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AdaptedMindApp());
    // Verify the app starts with the splash screen
    expect(find.text('AdaptedMind'), findsOneWidget);
  });
}
