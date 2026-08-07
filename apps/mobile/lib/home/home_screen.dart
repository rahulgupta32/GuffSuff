// ignore_for_file: prefer_const_constructors, deprecated_member_use
import 'package:flutter/material.dart';

import '../chats/chat_list_screen.dart';
import '../contacts/people_screen.dart';
import '../settings/settings_screen.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ChatListScreen(),
    PeopleScreen(),
    UpdatesPlaceholderScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(
              Icons.chat_bubble_rounded,
              color: AppTheme.primaryNavy,
            ),
            label: strings.tabChats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(
              Icons.people_rounded,
              color: AppTheme.primaryNavy,
            ),
            label: strings.tabPeople,
          ),
          NavigationDestination(
            icon: const Icon(Icons.update_rounded),
            selectedIcon: const Icon(
              Icons.update_rounded,
              color: AppTheme.primaryNavy,
            ),
            label: strings.tabUpdates,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(
              Icons.settings_rounded,
              color: AppTheme.primaryNavy,
            ),
            label: strings.tabSettings,
          ),
        ],
      ),
    );
  }
}

class UpdatesPlaceholderScreen extends StatelessWidget {
  const UpdatesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Updates')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_chat_unread_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'GuffSuff Status & Channels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Privacy-preserving status updates coming soon.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
