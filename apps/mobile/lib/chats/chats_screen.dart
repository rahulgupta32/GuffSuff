import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/widgets/empty_state.dart';
import '../data/repositories.dart';

final conversationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      // Use DemoRepository for dev/demo mode preview
      final repo = DemoRepository();
      return repo.getConversations();
    });

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: AppTypography.titleMedium,
                  decoration: InputDecoration(
                    hintText: strings.searchPlaceholder,
                    border: InputBorder.none,
                    hintStyle: AppTypography.titleMedium.copyWith(
                      color:
                          isDark
                              ? AppColors.darkContentMuted
                              : AppColors.lightContentMuted,
                    ),
                  ),
                  onChanged:
                      (val) => setState(() => _searchQuery = val.toLowerCase()),
                )
                : Text(
                  strings.appTitle,
                  style: AppTypography.display.copyWith(
                    fontSize: 22,
                    color: AppColors.brandPrimary,
                  ),
                ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => context.push('/chats/new'),
          ),
        ],
      ),
      body: conversationsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.interactivePrimary,
              ),
            ),
        error:
            (_, __) => EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Unable to load chats',
              description: 'Please check your connection and try again.',
            ),
        data: (conversations) {
          final filtered =
              conversations.where((c) {
                final name = (c['peerName'] as String).toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

          if (filtered.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              title: strings.noConversationsTitle,
              description: strings.noConversationsSub,
              actionLabel: strings.startChatAction,
              onAction: () => context.push('/chats/new'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
            itemCount: filtered.length,
            separatorBuilder:
                (_, __) => const Divider(
                  indent: 72,
                  endIndent: AppSpacing.s16,
                  height: 1,
                ),
            itemBuilder: (context, index) {
              final chat = filtered[index];
              return _ChatRow(
                chat: chat,
                onTap:
                    () => context.push(
                      '/chats/conversation/${chat['id']}?name=${Uri.encodeComponent(chat['peerName'])}',
                    ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final Map<String, dynamic> chat;
  final VoidCallback onTap;

  const _ChatRow({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.darkContentPrimary : AppColors.lightContentPrimary;
    final secondaryColor =
        isDark
            ? AppColors.darkContentSecondary
            : AppColors.lightContentSecondary;
    final mutedColor =
        isDark ? AppColors.darkContentMuted : AppColors.lightContentMuted;
    final unreadCount = chat['unreadCount'] as int? ?? 0;
    final isPinned = chat['isPinned'] as bool? ?? false;
    final isMuted = chat['isMuted'] as bool? ?? false;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
              child: Text(
                chat['peerAvatar'] ?? 'U',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat['peerName'] ?? '',
                          style: AppTypography.titleSmall.copyWith(
                            color: primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        chat['timestamp'] ?? '',
                        style: AppTypography.metadata.copyWith(
                          color:
                              unreadCount > 0
                                  ? AppColors.interactivePrimary
                                  : mutedColor,
                          fontWeight:
                              unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat['lastMessage'] ?? '',
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                unreadCount > 0 ? primaryColor : secondaryColor,
                            fontWeight:
                                unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMuted) ...[
                        const SizedBox(width: AppSpacing.s4),
                        Icon(
                          Icons.volume_off_rounded,
                          size: 14,
                          color: mutedColor,
                        ),
                      ],
                      if (isPinned) ...[
                        const SizedBox(width: AppSpacing.s4),
                        Icon(
                          Icons.push_pin_rounded,
                          size: 14,
                          color: mutedColor,
                        ),
                      ],
                      if (unreadCount > 0) ...[
                        const SizedBox(width: AppSpacing.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.interactivePrimary,
                            borderRadius: AppRadii.borderFull,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: AppTypography.metadata.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
