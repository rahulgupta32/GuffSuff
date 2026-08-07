import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../core/branding/app_theme.dart';

class DeviceItem {
  final String id;
  final String name;
  final String platform;
  final String lastActive;
  final bool isCurrent;

  const DeviceItem({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastActive,
    this.isCurrent = false,
  });
}

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  late List<DeviceItem> devices;

  @override
  void initState() {
    super.initState();
    devices = [
      const DeviceItem(
        id: 'dev_curr_01',
        name: 'Android Phone (Emulator)',
        platform: 'Android 15 (API 35 x86_64)',
        lastActive: 'Active Now',
        isCurrent: true,
      ),
      const DeviceItem(
        id: 'dev_sec_02',
        name: 'Linux Desktop Workstation',
        platform: 'Linux x86_64',
        lastActive: '2 hours ago',
      ),
    ];
  }

  void _revokeDevice(DeviceItem item) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Revoke Device'),
            content: Text(
              'Are you sure you want to revoke "${item.name}"? Cryptographic identity keys will be destroyed on that device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    devices.removeWhere((d) => d.id == item.id);
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Device ${item.name} revoked.')),
                  );
                },
                child: const Text(
                  'Revoke',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Linked Devices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.primaryNavy.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield, color: AppTheme.primaryNavy),
                      SizedBox(width: 8),
                      Text(
                        'Device Identity Safety',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Device ID: ${authState.deviceId ?? 'dev_android_emulator'}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Active Devices',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...devices.map((device) {
            return Card(
              child: ListTile(
                leading: Icon(
                  device.platform.contains('Android')
                      ? Icons.phone_android
                      : Icons.computer,
                  color: device.isCurrent ? AppTheme.primaryNavy : Colors.grey,
                ),
                title: Text(
                  device.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${device.platform} • ${device.lastActive}'),
                trailing:
                    device.isCurrent
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNavy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'This Device',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryNavy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        : IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _revokeDevice(device),
                        ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
