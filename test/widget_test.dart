import 'package:flutter_test/flutter_test.dart';
import 'package:uniclip/engine/engine.dart';
import 'package:uniclip/main.dart';

void main() {
  testWidgets('Devices screen smoke test', (WidgetTester tester) async {
    // Initialize Engine for testing since UI depends on it
    await Engine().start();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const UniclipApp());

    // Verify that the Uniclip Zone screen is shown
    expect(find.text('Uniclip Zone'), findsOneWidget);
  });
}
