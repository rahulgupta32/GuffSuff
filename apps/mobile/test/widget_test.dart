import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guffsuff_mobile/main.dart';

void main() {
  testWidgets('DevStatusScreen renders baseline title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GuffSuffApp()));
    expect(find.text('GuffSuff Mobile Application'), findsOneWidget);
  });
}
