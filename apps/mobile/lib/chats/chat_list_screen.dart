import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';
import 'new_chat_sheet.dart';

class DemoChatItem {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  const DemoChatItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });
}

const List<DemoChatItem> demoChats = [
  DemoChatItem(
    id: 'c1',
    name: 'Aarav Shrestha',
    avatar: 'A',
    lastMessage: 'नमस्ते! GuffSuff को आन्तरिक टेस्ट कस्तो हुँदैछ?',
    timestamp: '10:42 AM',
    unreadCount: 2,
    isPinned: true,
  ),
  DemoChatItem(
    id: 'c2',
    name: 'GuffSuff Dev Team 🇳🇵',
    avatar: 'G',
    lastMessage:
        'Phase 7 mobile demo is ready for internal phone installation!',
    timestamp: '9:15 AM',
    unreadCount: 0,
    isPinned: true,
  ),
  DemoChatItem(
    id: 'c3',
    name: 'Sita Gurung',
    avatar: 'S',
    lastMessage: 'Let us discuss the privacy requirements later.',
    timestamp: 'Yesterday',
    unreadCount: 0,
    isMuted: true,
  ),
  DemoChatItem(
    id: 'c4',
    name: 'Birgunj Tech Club',
    avatar: 'B',
    lastMessage: 'Welcome to GuffSuff internal build demo.',
    timestamp: 'Yesterday',
    unreadCount: 0,
  ),
];

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    final filteredChats =
        demoChats.where((c) {
          return c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              c.lastMessage.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Internal Diagnostics',
            onPressed: () => context.push('/diagnostics'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Demo Data Banner
          Container(
            width: double.infinity,
            color: Colors.amber.shade900.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.demoDataNotice,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search chats or messages...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredChats.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryNavy.withOpacity(0.15),
                    child: Text(
                      chat.avatar,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        chat.timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      if (chat.isMuted) ...[
                        const Icon(
                          Icons.volume_off,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryNavy,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    context.push(
                      '/chat/${chat.id}?name=${Uri.encodeComponent(chat.name)}',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryNavy,
        child: const Icon(Icons.message_rounded, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => const NewChatSheet(),
          );
        },
      ),
    );
  }
}
