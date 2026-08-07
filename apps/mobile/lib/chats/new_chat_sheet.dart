import 'package:flutter/material.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.startChatAction)),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.brandPrimary,
              child: Icon(Icons.group_add_rounded, color: Colors.white),
            ),
            title: Text(strings.newGroup, style: AppTypography.titleSmall),
            subtitle: const Text('Create a conversation group'),
            onTap: () {},
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.interactivePrimary,
              child: Icon(Icons.person_add_rounded, color: Colors.white),
            ),
            title: Text(strings.newContact, style: AppTypography.titleSmall),
            subtitle: const Text('Add by phone number'),
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
              style: AppTypography.labelMedium.copyWith(color: Colors.grey),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
              child: const Text(
                'A',
                style: TextStyle(color: AppColors.brandPrimary),
              ),
            ),
            title: const Text('Aanav Sharma'),
            subtitle: const Text('+977 9841234567'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
              child: const Text(
                'S',
                style: TextStyle(color: AppColors.brandPrimary),
              ),
            ),
            title: const Text('Sara Shrestha'),
            subtitle: const Text('+977 9851098765'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
