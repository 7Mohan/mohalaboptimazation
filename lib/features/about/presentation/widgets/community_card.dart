import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/about_config.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';

/// Interactive community hub presenting official Telegram and TikTok entry points.
class CommunityCard extends ConsumerWidget {
  const CommunityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = ref.watch(aboutConfigProvider);
    final launcher = ref.watch(urlLauncherServiceProvider);

    const telegramBlue = Color(0xFF229ED9);
    const tikTokPink = Color(0xFFFE2C55);

    final isTelegramConfigured = AboutConfig.isValidUrl(config.telegramCommunityUrl);
    final isTikTokConfigured = AboutConfig.isValidUrl(config.tiktokCommunityUrl);

    return GlassCard(
      level: AppGlassLevel.level2,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E56DE).withOpacity(0.15),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFF5B93FF),
                  size: AppSizes.iconSm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official Communities',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Join discussions, get updates & tweak presets',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const MohaStatusBadge(
                type: MohaStatusType.safe,
                customLabel: 'Verified',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Telegram Tile
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: telegramBlue.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: telegramBlue.withOpacity(0.18),
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: telegramBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telegram Lab',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        config.telegramCommunityHandle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: telegramBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy Telegram Link',
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: config.telegramCommunityUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Telegram link copied!'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: telegramBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isTelegramConfigured
                      ? () => launcher.launchOrCopy(
                            context,
                            config.telegramCommunityUrl,
                            title: 'Telegram Community',
                          )
                      : null,
                  child: const Text('Join', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // TikTok Tile
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: tikTokPink.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tikTokPink.withOpacity(0.18),
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: tikTokPink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TikTok Showcase',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        config.tiktokCommunityHandle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tikTokPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy TikTok Link',
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: config.tiktokCommunityUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('TikTok link copied!'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tikTokPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isTikTokConfigured
                      ? () => launcher.launchOrCopy(
                            context,
                            config.tiktokCommunityUrl,
                            title: 'TikTok Profile',
                          )
                      : null,
                  child: const Text('Follow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
