import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_tokens.dart';
import '../data/repositories.dart';

final devicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = DemoRepository();
  return repo.getDevices();
});

class LinkedDevicesScreen extends ConsumerWidget {
  const LinkedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Linked Devices')),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load devices')),
        data:
            (devices) => ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final dev = devices[index];
                final isCurrent = dev['isCurrent'] == true;
                return ListTile(
                  leading: Icon(
                    isCurrent
                        ? Icons.phone_android_rounded
                        : Icons.laptop_rounded,
                    color: isCurrent ? AppColors.brandPrimary : Colors.grey,
                  ),
                  title: Text(
                    dev['name'] ?? '',
                    style: AppTypography.titleSmall,
                  ),
                  subtitle: Text('${dev['platform']} • ${dev['lastActive']}'),
                  trailing:
                      isCurrent
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: AppRadii.borderFull,
                            ),
                            child: const Text(
                              'This Device',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : IconButton(
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.danger,
                            ),
                            onPressed: () {},
                          ),
                );
              },
            ),
      ),
    );
  }
}
