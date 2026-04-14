import 'package:flutter_test/flutter_test.dart';

import 'package:fuelproof/main.dart';
import 'package:fuelproof/features/splash/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders on app start', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump();
  });
}
