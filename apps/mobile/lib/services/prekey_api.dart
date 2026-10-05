import 'dart:convert';
import 'auth_session.dart';

/// Public material only. Native libsignal must authenticate signatures and pins.
class PublicPrekeyBundle {
  final Map<String, dynamic> json;
  PublicPrekeyBundle._(this.json);

  factory PublicPrekeyBundle.parse(
    dynamic value, {
    required DateTime now,
    String? expectedDeviceId,
  }) {
    final claim = expectedDeviceId != null;
    final fields = <String>{
      'protocolVersion',
      'registrationId',
      'identityPublicKeyBase64',
      'signedPrekeyId',
      'signedPrekeyPublicBase64',
      'signedPrekeySignatureBase64',
      'kemPrekeyId',
      'kemPrekeyPublicBase64',
      'kemPrekeySignatureBase64',
      'expiresAt',
      if (claim) ...[
        'deviceId',
        'oneTimePrekeyId',
        'oneTimePrekeyPublicBase64',
      ] else
        'oneTimePrekeys',
    };
    final data = publicObject(value, fields);
    if (publicInteger(data['protocolVersion'], 2, 2) != 2) {
      throw const FormatException('Modern bundle required');
    }
    publicInteger(data['registrationId'], 1, 16380);
    for (final field in ['signedPrekeyId', 'kemPrekeyId']) {
      publicInteger(data[field], 0, 2147483647);
    }
    for (final field in [
      'identityPublicKeyBase64',
      'signedPrekeyPublicBase64',
    ]) {
      publicBytes(data[field], 33, 33, curve: true);
    }
    for (final field in [
      'signedPrekeySignatureBase64',
      'kemPrekeySignatureBase64',
    ]) {
      publicBytes(data[field], 64, 64);
    }
    publicBytes(data['kemPrekeyPublicBase64'], 1, 4096);
    final expires = publicExpiry(data['expiresAt']);
    if (!expires.isAfter(now) ||
        expires.isAfter(now.add(const Duration(days: 30)))) {
      throw const FormatException('Invalid bundle expiry');
    }
    if (claim) {
      if (publicId(data['deviceId']) != publicId(expectedDeviceId)) {
        throw const FormatException('Claim device mismatch');
      }
      publicInteger(data['oneTimePrekeyId'], 0, 2147483647);
      publicBytes(data['oneTimePrekeyPublicBase64'], 33, 33, curve: true);
      data['deviceId'] = publicId(data['deviceId']);
    } else {
      final keys = data['oneTimePrekeys'];
      if (keys is! List || keys.length > 100) {
        throw const FormatException('Invalid prekey inventory');
      }
      final ids = <int>{};
      final encodings = <String>{};
      data['oneTimePrekeys'] = List.unmodifiable(
        keys.map((value) {
          final key = publicObject(value, {'keyId', 'publicKeyBase64'});
          final id = publicInteger(key['keyId'], 0, 2147483647);
          publicBytes(key['publicKeyBase64'], 33, 33, curve: true);
          if (!ids.add(id) ||
              !encodings.add(key['publicKeyBase64'] as String)) {
            throw const FormatException('Duplicate one-time prekey');
          }
          return Map<String, dynamic>.unmodifiable(key);
        }),
      );
    }
    return PublicPrekeyBundle._(Map.unmodifiable(data));
  }
}

class PrekeyApi {
  final AuthSession session;
  final DateTime Function() clock;
  PrekeyApi(this.session, {DateTime Function()? clock})
    : clock = clock ?? (() => DateTime.now().toUtc());

  Future<int> publish(dynamic publicBundle) async {
    final device = publicId(session.deviceId);
    final bundle = PublicPrekeyBundle.parse(publicBundle, now: clock());
    final result = publicObject(
      await session.postJson('devices/current/prekeys', bundle.json),
      {'deviceId', 'availablePrekeys'},
    );
    if (publicId(result['deviceId']) != device) {
      throw const FormatException('Publication device mismatch');
    }
    return publicInteger(result['availablePrekeys'], 0, 1000);
  }

  /// Caller must persist claimId before requesting and reuse it after a restart.
  Future<PublicPrekeyBundle> claim({
    required String conversationId,
    required String deviceId,
    required String claimId,
  }) async {
    final target = publicId(deviceId);
    if (target == publicId(session.deviceId)) {
      throw const FormatException('Cannot claim own device');
    }
    final response = await session.postJson(
      'conversations/${publicId(conversationId)}/devices/$target/prekey-claims',
      {'claimId': publicId(claimId)},
    );
    return PublicPrekeyBundle.parse(
      response,
      now: clock(),
      expectedDeviceId: target,
    );
  }

  Future<List<String>> recipientDevices(
    String conversationId,
    String recipientUserId,
  ) async {
    final peer = publicId(recipientUserId);
    if (peer == publicId(session.userId)) {
      throw const FormatException('Recipient must be another account');
    }
    final response = await session.getJson(
      'conversations/${publicId(conversationId)}/recipients/$peer/devices',
    );
    if (response is! List || response.isEmpty || response.length > 16) {
      throw const FormatException('Unsupported recipient inventory');
    }
    final devices =
        response
            .map((entry) => publicId(publicObject(entry, {'id'})['id']))
            .toList();
    if (devices.toSet().length != devices.length ||
        devices.contains(publicId(session.deviceId))) {
      throw const FormatException('Invalid recipient devices');
    }
    devices.sort();
    return List.unmodifiable(devices);
  }
}

Map<String, dynamic> publicObject(dynamic value, Set<String> fields) {
  if (value is! Map<String, dynamic> ||
      value.length != fields.length ||
      !value.keys.every(fields.contains)) {
    throw const FormatException('Invalid public response shape');
  }
  return Map<String, dynamic>.from(value);
}

String publicId(dynamic value) {
  if (value is! String ||
      !RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value)) {
    throw const FormatException('Invalid identifier');
  }
  return value.toLowerCase();
}

int publicInteger(dynamic value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('Invalid integer');
  }
  return value;
}

void publicBytes(dynamic value, int min, int max, {bool curve = false}) {
  if (value is! String || value.length > ((max + 2) ~/ 3) * 4) {
    throw const FormatException('Invalid public encoding');
  }
  final bytes = base64Decode(value);
  if (bytes.length < min ||
      bytes.length > max ||
      base64Encode(bytes) != value ||
      (curve && bytes.first != 5)) {
    throw const FormatException('Invalid public encoding');
  }
}

DateTime publicExpiry(dynamic value) {
  if (value is! String ||
      !RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,3})?Z$',
      ).hasMatch(value)) {
    throw const FormatException('Invalid UTC timestamp');
  }
  final parsed = DateTime.parse(value);
  String normalized(String date) {
    var body = date.substring(0, date.length - 1);
    if (body.contains('.')) {
      while (body.endsWith('0')) {
        body = body.substring(0, body.length - 1);
      }
      if (body.endsWith('.')) {
        body = body.substring(0, body.length - 1);
      }
    }
    return '${body}Z';
  }

  if (normalized(parsed.toUtc().toIso8601String()) != normalized(value)) {
    throw const FormatException('Invalid calendar timestamp');
  }
  return parsed;
}
