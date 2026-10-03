import 'package:flutter/material.dart';
import '../services/auth_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<dynamic> _profile = authSession.getJson('account');
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: FutureBuilder<dynamic>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to load profile. Please try again.'),
          );
        }
        final profile = snapshot.data as Map<String, dynamic>;
        return ListView(
          children: [
            ListTile(
              title: const Text('Display name'),
              subtitle: Text(profile['display_name'] as String? ?? ''),
            ),
            ListTile(
              title: const Text('Username'),
              subtitle: Text('@${profile['username_display'] ?? ''}'),
            ),
            ListTile(
              title: const Text('Bio'),
              subtitle: Text(profile['bio'] as String? ?? ''),
            ),
          ],
        );
      },
    ),
  );
}
