import 'package:flutter_test/flutter_test.dart';
import 'package:mygarage/main.dart';

void main() {
  testWidgets('App builds and shows placeholder smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyGarageApp());

    expect(find.text('Firebase is Initialized!\nReady for Step 1.'), findsOneWidget);
  });
}