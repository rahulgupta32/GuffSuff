import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Safety')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Read Receipts'),
            subtitle: const Text(
              'Allow others to see when you have read their messages',
            ),
            value: true,
            onChanged: (val) {},
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Last Seen & Online'),
            subtitle: const Text('Control who can see your online status'),
            value: true,
            onChanged: (val) {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Blocked Contacts'),
            subtitle: const Text('0 contacts blocked'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
