import 'package:flutter/material.dart';


class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.shade900.withOpacity(0.1),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Features dependent on production E2EE are marked unavailable in this demo build.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: true,
            onChanged: null,
            title: const Text('Read Receipts'),
            subtitle: const Text(
              'Send read receipts when messages are viewed (Requires E2EE)',
            ),
          ),
          SwitchListTile(
            value: false,
            onChanged: null,
            title: const Text('Last Seen & Online Status'),
            subtitle: const Text('Control who can see your online state'),
          ),
          ListTile(
            title: const Text('Disappearing Messages'),
            subtitle: const Text('Off (Requires E2EE state enforcement)'),
            enabled: false,
          ),
          ListTile(
            title: const Text('Blocked Users'),
            subtitle: const Text('0 blocked contacts'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
