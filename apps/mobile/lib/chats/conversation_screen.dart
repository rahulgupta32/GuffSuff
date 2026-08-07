import 'package:flutter/material.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../crypto/provider_neutral_boundary.dart';

class ConversationScreen extends StatelessWidget {
  final String conversationId;
  final String peerName;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.peerName,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const MobileCryptoProvider activeProvider = UnavailableCryptoProvider();
    final bool isProviderAvailable = activeProvider.isAvailable;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
              child: Text(
                peerName.isNotEmpty ? peerName[0] : 'U',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerName,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Single contextual non-intrusive security notice
          if (!isProviderAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s8,
              ),
              color:
                  isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.lightSurfaceSecondary,
              child: Row(
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    size: 16,
                    color:
                        isDark
                            ? AppColors.darkContentMuted
                            : AppColors.lightContentMuted,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      strings.providerUnavailableTitle,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark
                                ? AppColors.darkContentSecondary
                                : AppColors.lightContentSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                _MessageBubble(
                  text: 'Namaste! Welcome to GuffSuff.',
                  isOutgoing: false,
                  timestamp: '10:40 AM',
                ),
                const SizedBox(height: AppSpacing.s8),
                _MessageBubble(
                  text: 'Namaste! Testing the production design system.',
                  isOutgoing: true,
                  timestamp: '10:42 AM',
                  status: 'delivered',
                ),
              ],
            ),
          ),
          // Subtle Disabled Composer Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.lightSurfaceSecondary,
              border: Border(
                top: BorderSide(
                  color:
                      isDark
                          ? AppColors.darkBorderSubtle
                          : AppColors.lightBorderSubtle,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color:
                        isDark
                            ? AppColors.darkInteractiveDisabled
                            : AppColors.lightInteractiveDisabled,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(
                      'Messaging disabled until provider activation',
                      style: AppTypography.bodyMedium.copyWith(
                        color:
                            isDark
                                ? AppColors.darkContentMuted
                                : AppColors.lightContentMuted,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.send_rounded,
                    color:
                        isDark
                            ? AppColors.darkInteractiveDisabled
                            : AppColors.lightInteractiveDisabled,
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

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isOutgoing;
  final String timestamp;
  final String? status;

  const _MessageBubble({
    required this.text,
    required this.isOutgoing,
    required this.timestamp,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor =
        isOutgoing
            ? AppColors.brandPrimary
            : (isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceSecondary);
    final textColor =
        isOutgoing
            ? Colors.white
            : (isDark
                ? AppColors.darkContentPrimary
                : AppColors.lightContentPrimary);
    final metaColor =
        isOutgoing
            ? Colors.white70
            : (isDark
                ? AppColors.darkContentMuted
                : AppColors.lightContentMuted);

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadii.bubble),
            topRight: const Radius.circular(AppRadii.bubble),
            bottomLeft: Radius.circular(
              isOutgoing ? AppRadii.bubble : AppRadii.small,
            ),
            bottomRight: Radius.circular(
              isOutgoing ? AppRadii.small : AppRadii.bubble,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: AppTypography.bodyMedium.copyWith(color: textColor),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timestamp,
                  style: AppTypography.metadata.copyWith(color: metaColor),
                ),
                if (isOutgoing && status != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded, size: 14, color: metaColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
