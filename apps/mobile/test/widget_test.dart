import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guffsuff_mobile/main.dart';
import 'package:guffsuff_mobile/core/router/app_router.dart';

void main() {
  testWidgets('signed-out app opens onboarding instead of chats', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GuffSuffApp()));
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Chats'), findsNothing);
    appRouter.go('/chats');
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, '/welcome');
    appRouter.go('/profile-setup');
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, '/phone-entry');
  });
}
