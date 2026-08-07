import 'package:flutter/material.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';

class NewChatSheet extends StatelessWidget {
  const NewChatSheet({super.key});

  void _showDisabledDialog(BuildContext context, String actionTitle) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.lock_clock_outlined,
                  color: AppTheme.accentCrimson,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    actionTitle,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Text(strings.providerUnavailableDetail),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start New Conversation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryNavy,
              child: Icon(Icons.group_add, color: Colors.white),
            ),
            title: const Text('New Group Chat'),
            subtitle: const Text('Create group conversation'),

            onTap: () {
              Navigator.pop(context);
              _showDisabledDialog(context, 'Group Creation Disabled');
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryNavy,
              child: Icon(Icons.person_add, color: Colors.white),
            ),
            title: const Text('New Direct Chat'),
            subtitle: const Text('Start 1-on-1 private chat'),
            onTap: () {
              Navigator.pop(context);
              _showDisabledDialog(context, 'Direct Chat Disabled');
            },
          ),
        ],
      ),
    );
  }
}
