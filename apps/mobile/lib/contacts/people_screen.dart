import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../data/repositories.dart';

final contactsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final repo = DemoRepository();
    return repo.getContacts();
  },
);

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  bool _hasPermission = true;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.tabPeople)),
      body: ListView(
        children: [
          // Contextual Educational CTA row before/during permission request
          if (!_hasPermission)
            Container(
              margin: const EdgeInsets.all(AppSpacing.s16),
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.darkSurfaceSecondary
                        : AppColors.lightSurfaceSecondary,
                borderRadius: AppRadii.borderMedium,
                border: Border.all(
                  color:
                      isDark
                          ? AppColors.darkBorderSubtle
                          : AppColors.lightBorderSubtle,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.contacts_rounded,
                    color: AppColors.brandPrimary,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.findPeoplePrompt,
                          style: AppTypography.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          strings.contactsPermissionSub,
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                isDark
                                    ? AppColors.darkContentSecondary
                                    : AppColors.lightContentSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        ElevatedButton(
                          onPressed:
                              () => setState(() => _hasPermission = true),
                          child: const Text('Find Contacts'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.brandPrimary,
              child: Icon(
                Icons.group_add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(strings.newGroup, style: AppTypography.titleSmall),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.interactivePrimary,
              child: Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(strings.newContact, style: AppTypography.titleSmall),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s8,
            ),
            child: Text(
              strings.contactsOnGuffSuff,
              style: AppTypography.labelMedium.copyWith(
                color:
                    isDark
                        ? AppColors.darkContentMuted
                        : AppColors.lightContentMuted,
              ),
            ),
          ),
          contactsAsync.when(
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.s24),
                    child: CircularProgressIndicator(),
                  ),
                ),
            error:
                (_, __) =>
                    const ListTile(title: Text('Unable to load contacts')),
            data: (contacts) {
              final onGuffSuff =
                  contacts.where((c) => c['onGuffSuff'] == true).toList();
              final notOnGuffSuff =
                  contacts.where((c) => c['onGuffSuff'] != true).toList();

              return Column(
                children: [
                  ...onGuffSuff.map(
                    (c) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brandPrimary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          (c['displayName'] as String)[0],
                          style: const TextStyle(color: AppColors.brandPrimary),
                        ),
                      ),
                      title: Text(
                        c['displayName'],
                        style: AppTypography.titleSmall,
                      ),
                      subtitle: Text(c['phoneNumber']),
                      onTap: () {},
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.inviteToGuffSuff,
                        style: AppTypography.labelMedium.copyWith(
                          color:
                              isDark
                                  ? AppColors.darkContentMuted
                                  : AppColors.lightContentMuted,
                        ),
                      ),
                    ),
                  ),
                  ...notOnGuffSuff.map(
                    (c) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade400,
                        child: Text(
                          (c['displayName'] as String)[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        c['displayName'],
                        style: AppTypography.titleSmall,
                      ),
                      subtitle: Text(c['phoneNumber']),
                      trailing: TextButton(
                        onPressed: () {},
                        child: const Text('Invite'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
