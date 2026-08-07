import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guffsuff_mobile/main.dart';

void main() {
  testWidgets('GuffSuffApp renders baseline home screen smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GuffSuffApp()));
    await tester.pumpAndSettle();
    expect(find.text('GuffSuff'), findsOneWidget);
    expect(find.text('GuffSuff Dev Team 🇳🇵'), findsOneWidget);
  });
}
