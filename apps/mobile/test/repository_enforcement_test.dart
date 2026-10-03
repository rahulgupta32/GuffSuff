import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/data/repositories.dart';

void main() {
  group('Production Repository Enforcement Tests', () {
    test('Development environment permits DemoRepository registration', () {
      final demoRepo = DemoRepository();
      expect(
        () => RepositoryRegistry(
          isProduction: false,
          profileRepo: demoRepo,
          deviceRepo: demoRepo,
          contactRepo: demoRepo,
          conversationRepo: demoRepo,
        ),
        returnsNormally,
      );
    });

    test(
      'Production environment permits ProductionApiRepository registration',
      () {
        final prodRepo = ProductionApiRepository();
        expect(
          () => RepositoryRegistry(
            isProduction: true,
            profileRepo: prodRepo,
            deviceRepo: prodRepo,
            contactRepo: prodRepo,
            conversationRepo: prodRepo,
          ),
          returnsNormally,
        );
      },
    );

    test(
      'Production environment registration of DemoRepository THROWS StateError',
      () {
        final demoRepo = DemoRepository();

        expect(
          () => RepositoryRegistry(
            isProduction: true,
            profileRepo: demoRepo,
            deviceRepo: demoRepo,
            contactRepo: demoRepo,
            conversationRepo: demoRepo,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                'FATAL: DemoRepository registered in PRODUCTION environment.',
              ),
            ),
          ),
        );
      },
    );

    test(
      'Production cannot silently fall back to DemoRepository on API failure',
      () async {
        final prodRepo = ProductionApiRepository();
        await expectLater(
          prodRepo.getProfile('user_123'),
          throwsA(isA<Exception>()),
        );

        // Must return null / offline error state, NEVER mock Demo profile data
      },
    );

    test(
      'Failed API initialization returns empty list, NOT mock conversations',
      () async {
        final prodRepo = ProductionApiRepository();
        await expectLater(
          prodRepo.getConversations(),
          throwsA(isA<Exception>()),
        );

        // Must return empty list, NOT mock demo conversations
      },
    );
  });
}
