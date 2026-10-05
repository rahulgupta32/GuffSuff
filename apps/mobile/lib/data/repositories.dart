import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_session.dart';

final authenticationProvider = Provider<bool>((ref) {
  void changed() {
    ref.invalidateSelf();
  }

  authSession.addListener(changed);
  ref.onDispose(() => authSession.removeListener(changed));
  return authSession.isAuthenticated;
});

abstract class ProfileRepository {
  Future<Map<String, dynamic>?> getProfile(String userId);
}

abstract class DeviceRepository {
  Future<List<Map<String, dynamic>>> getDevices();
}

abstract class ContactRepository {
  Future<List<Map<String, dynamic>>> getContacts();
}

abstract class ConversationRepository {
  Future<List<Map<String, dynamic>>> getConversations();
}

/// Production implementation backed strictly by गफसफ NestJS backend endpoints.
class ProductionApiRepository
    implements
        ProfileRepository,
        DeviceRepository,
        ContactRepository,
        ConversationRepository {
  final AuthSession session;
  ProductionApiRepository({AuthSession? session})
    : session = session ?? authSession;
  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async =>
      await session.getJson('account') as Map<String, dynamic>;
  @override
  Future<List<Map<String, dynamic>>> getDevices() async {
    final data = await session.getJson('devices') as List;
    return data.map((value) {
      final d = value as Map<String, dynamic>;
      return {
        ...d,
        'name': d['deviceName'] ?? d['device_name'] ?? 'Device',
        'deviceId': d['id'],
        'isCurrent': d['isCurrentDevice'] ?? false,
        'lastActive': d['lastSeenAt'] ?? d['last_seen_at'] ?? '',
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getContacts() async =>
      throw UnsupportedError('Contact discovery is not available yet.');
  @override
  Future<List<Map<String, dynamic>>> getConversations() async {
    final data = await session.getJson('conversations') as List;
    return data.map((value) {
      final c = value as Map<String, dynamic>;
      return {
        ...c,
        'peerName': 'Conversation',
        'peerAvatar': 'ग',
        'lastMessage': '',
        'timestamp': '',
        'unreadCount': 0,
      };
    }).toList();
  }
}

/// Development preview repository providing realistic mock data for UI design testing.
class DemoRepository
    implements
        ProfileRepository,
        DeviceRepository,
        ContactRepository,
        ConversationRepository {
  static const bool isDemo = true;

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return {
      'id': userId,
      'displayName': 'Rahul Gupta',
      'username': 'rahul_g',
      'phoneNumber': '+977 9800000000',
      'bio': 'Building गफसफ for Nepal 🇳🇵',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getDevices() async {
    return [
      {
        'deviceId': 'dev_pixel_8',
        'name': 'Pixel 8 Pro (This Device)',
        'platform': 'Android 15',
        'lastActive': 'Active now',
        'isCurrent': true,
      },
      {
        'deviceId': 'dev_macbook_pro',
        'name': 'गफसफ Web / Desktop',
        'platform': 'macOS Sequoia',
        'lastActive': '2 hours ago',
        'isCurrent': false,
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getContacts() async {
    return [
      {
        'id': 'u_aanav',
        'displayName': 'Aanav Sharma',
        'username': 'aanav_s',
        'phoneNumber': '+977 9841234567',
        'onGuffSuff': true,
      },
      {
        'id': 'u_sara',
        'displayName': 'Sara Shrestha',
        'username': 'sara_shrestha',
        'phoneNumber': '+977 9851098765',
        'onGuffSuff': true,
      },
      {
        'id': 'u_bibek',
        'displayName': 'Bibek Thapa',
        'username': 'bibek_t',
        'phoneNumber': '+977 9812345678',
        'onGuffSuff': true,
      },
      {
        'id': 'u_prashant',
        'displayName': 'Prashant Karki',
        'phoneNumber': '+977 9867890123',
        'onGuffSuff': false,
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getConversations() async {
    return [
      {
        'id': 'conv_1',
        'peerName': 'Aanav Sharma',
        'peerAvatar': 'A',
        'lastMessage': 'Tap Tap 🇳🇵 गफसफ test envelope',
        'timestamp': '10:42 AM',
        'unreadCount': 2,
        'isPinned': true,
        'isMuted': false,
      },
      {
        'id': 'conv_2',
        'peerName': 'Sara Shrestha',
        'peerAvatar': 'S',
        'lastMessage': 'Namaste! Are you joining the call?',
        'timestamp': 'Yesterday',
        'unreadCount': 0,
        'isPinned': false,
        'isMuted': false,
      },
      {
        'id': 'conv_3',
        'peerName': 'Kathmandu Dev Community',
        'peerAvatar': 'K',
        'lastMessage': 'Bibek: Flutter 3.44 update looks smooth.',
        'timestamp': 'Aug 5',
        'unreadCount': 0,
        'isPinned': false,
        'isMuted': true,
      },
    ];
  }
}

/// Registry ensuring production environments throw error if DemoRepository is passed.
class RepositoryRegistry {
  final bool isProduction;
  final ProfileRepository profileRepo;
  final DeviceRepository deviceRepo;
  final ContactRepository contactRepo;
  final ConversationRepository conversationRepo;

  RepositoryRegistry({
    required this.isProduction,
    required this.profileRepo,
    required this.deviceRepo,
    required this.contactRepo,
    required this.conversationRepo,
  }) {
    if (isProduction) {
      if (profileRepo is DemoRepository ||
          deviceRepo is DemoRepository ||
          contactRepo is DemoRepository ||
          conversationRepo is DemoRepository) {
        throw StateError(
          'FATAL: DemoRepository registered in PRODUCTION environment.',
        );
      }
    }
  }
}
