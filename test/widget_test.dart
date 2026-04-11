import 'package:flutter_test/flutter_test.dart';

import 'package:fuelproof/main.dart';

void main() {
  testWidgets('Splash screen renders on app start', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('FuelProof'), findsWidgets);
    expect(find.byType(MyApp), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();
  });
}
