import 'package:flutter_test/flutter_test.dart';
import 'package:anoa_dashboard/main.dart';

void main() {
  testWidgets('ANOA Dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AnoaApp());
    expect(find.byType(AnoaApp), findsOneWidget);
  });
}
