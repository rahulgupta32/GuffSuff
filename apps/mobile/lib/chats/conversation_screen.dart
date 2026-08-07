import 'package:flutter/material.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';

class DemoMessage {
  final String text;
  final bool isMe;
  final String timestamp;

  const DemoMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class ConversationScreen extends StatelessWidget {
  final String chatId;
  final String chatName;

  const ConversationScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    final List<DemoMessage> messages = [
      const DemoMessage(
        text: 'नमस्ते! GuffSuff को नयाँ मोबाइल बिल्ड कस्तो छ?',
        isMe: false,
        timestamp: '10:30 AM',
      ),
      const DemoMessage(
        text:
            'Build is running on Android emulator with provider-neutral boundary!',
        isMe: true,
        timestamp: '10:32 AM',
      ),
      const DemoMessage(
        text: 'Great! Are real messages enabled yet?',
        isMe: false,
        timestamp: '10:35 AM',
      ),
      const DemoMessage(
        text:
            'No, secure messaging is disabled until an approved production crypto provider is integrated.',
        isMe: true,
        timestamp: '10:36 AM',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryNavy.withOpacity(0.2),
              child: Text(
                chatName.isNotEmpty ? chatName[0] : 'U',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Secure Messaging Unavailable (Internal Demo)',
                    style: TextStyle(fontSize: 11, color: Colors.amber),
                  ),

                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Disabled messaging notice banner
          Container(
            width: double.infinity,
            color: Colors.red.shade900.withOpacity(0.85),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_clock_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.providerUnavailableTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment:
                      msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color:
                          msg.isMe
                              ? AppTheme.primaryNavy
                              : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight:
                            msg.isMe ? Radius.zero : const Radius.circular(16),
                        bottomLeft:
                            !msg.isMe ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isMe ? Colors.white : null,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.timestamp,
                          style: TextStyle(
                            color: msg.isMe ? Colors.white70 : Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Disabled composer widget
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade800, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: null, // Disabled
                  ),
                  Expanded(
                    child: TextField(
                      enabled: false, // Disabled composer
                      decoration: InputDecoration(
                        hintText: 'Message sending disabled in demo build...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.grey),
                    onPressed: null, // Disabled
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
