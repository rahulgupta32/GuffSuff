// ignore_for_file: prefer_const_constructors, deprecated_member_use
import 'package:flutter/material.dart';

import '../core/branding/app_theme.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  bool contactsPermissionGranted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('People & Contacts')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.contacts, color: AppTheme.primaryNavy),
                        SizedBox(width: 12),
                        Text(
                          'Contacts Permission',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'GuffSuff respects your privacy. Contacts are matched locally using privacy-preserving phone numbers when enabled.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),

                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(
                          () =>
                              contactsPermissionGranted =
                                  !contactsPermissionGranted,
                        );
                      },
                      icon: Icon(
                        contactsPermissionGranted
                            ? Icons.check_circle
                            : Icons.add_moderator,
                      ),
                      label: Text(
                        contactsPermissionGranted
                            ? 'Contacts Permission Active'
                            : 'Enable Contacts Discovery',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            contactsPermissionGranted
                                ? Colors.green.shade800
                                : AppTheme.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'GuffSuff Members in Nepal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(child: Text('A')),
              title: const Text('Aarav Shrestha'),
              subtitle: const Text('@aarav_s • Kathmandu'),
              trailing: OutlinedButton(
                onPressed: () {},
                child: const Text('Invite'),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('P')),
              title: const Text('Prashant Sharma'),
              subtitle: const Text('@prashant_p • Pokhara'),
              trailing: OutlinedButton(
                onPressed: () {},
                child: const Text('Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
