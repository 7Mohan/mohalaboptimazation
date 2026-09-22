import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/about_config.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';

class AnnouncementsFeedWidget extends ConsumerWidget {
  const AnnouncementsFeedWidget({super.key});

  static const List<_AnnouncementItem> _announcements = [
    _AnnouncementItem(
      tag: 'NEW RELEASE',
      tagColor: Color(0xFF10B981),
      title: 'Moha Lab Optimization v2.0 Live',
      date: 'Sept 2026',
      summary:
          'AMOLED Black theme, per-game tuning presets, storage cleaner, and live CPU telemetry are now fully active.',
    ),
    _AnnouncementItem(
      tag: 'FEATURE UPDATE',
      tagColor: Color(0xFF3B82F6),
      title: 'Privileged Shizuku Integration',
      date: 'Sept 2026',
      summary:
          'Execute elevated Android system tweaks seamlessly without needing full root permissions.',
    ),
    _AnnouncementItem(
      tag: 'COMMUNITY',
      tagColor: Color(0xFF8B5CF6),
      title: 'Moha Lab Official Telegram Channel',
      date: 'Official',
      summary:
          'Get instant update notifications, request game profiles, and report benchmark feedback directly.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final launcher = ref.watch(urlLauncherServiceProvider);
    final config = ref.watch(aboutConfigProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0088CC).withAlpha(25),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Color(0xFF0088CC),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Lab News & Announcements',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088CC).withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Text(
                    'TELEGRAM FEED',
                    style: TextStyle(
                      color: Color(0xFF0088CC),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Announcement Items
            ..._announcements.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.tagColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.tag,
                            style: TextStyle(
                              color: item.tagColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          item.date,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.summary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSpacing.xs),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0088CC),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      launcher.launchOrCopy(
                        context,
                        config.telegramCommunityUrl,
                        title: 'Telegram Community',
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Open Telegram',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.outlined(
                  tooltip: 'Share Moha Lab',
                  onPressed: () {
                    Share.share(
                      'Check out Moha Lab Optimization for Android — clean performance tuning, gaming presets, and hardware diagnostics! ${config.telegramCommunityUrl}',
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementItem {
  const _AnnouncementItem({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.date,
    required this.summary,
  });

  final String tag;
  final Color tagColor;
  final String title;
  final String date;
  final String summary;
}
