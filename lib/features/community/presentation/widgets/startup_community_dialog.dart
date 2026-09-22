import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../../onboarding/presentation/widgets/how_to_use_dialog.dart';
import '../../../settings/presentation/providers/theme_provider.dart';

const _kCommunityModalSeenKey = 'has_seen_community_modal_v2';

/// Dismissible, non-trapping first-launch community welcome modal.
///
/// Promotes the official Telegram & TikTok communities while ensuring
/// the user can instantly dismiss and access the lab without impediment.
class StartupCommunityDialog extends ConsumerWidget {
  const StartupCommunityDialog({super.key});

  /// Displays the dialog if it has not been seen before on this device.
  static Future<void> showIfFirstLaunch(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final hasSeen = prefs.getBool(_kCommunityModalSeenKey) ?? false;
      if (!hasSeen && context.mounted) {
        await prefs.setBool(_kCommunityModalSeenKey, true);
        if (context.mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: true,
            barrierColor: Colors.black.withOpacity(0.65),
            builder: (ctx) => const StartupCommunityDialog(),
          );
        }
      }
    } catch (_) {
      // In tests or if SharedPreferences is not ready, gracefully ignore
    }
  }

  /// Explicitly show the modal from Settings or About
  static Future<void> showExplicit(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => const StartupCommunityDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final launcher = ref.watch(urlLauncherServiceProvider);

    const telegramBlue = Color(0xFF229ED9);
    const tikTokPink = Color(0xFFFE2C55);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        level: AppGlassLevel.level4,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E56DE).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MOHA LAB',
                          style: TextStyle(
                            color: Color(0xFF5B93FF),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const MohaStatusBadge(
                        type: MohaStatusType.safe,
                        customLabel: 'Official Hub',
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.of(context).pop();
                      HowToUseDialog.showIfFirstLaunch(context, ref);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Title & Subtitle
              Text(
                'Welcome to the Lab',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connect with the official Moha Lab channels for early release APKs, verified game profiles, and benchmark discussions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Channel 1: Telegram
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: telegramBlue.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: telegramBlue.withOpacity(0.20),
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: telegramBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Telegram Channel',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '@Mohagaminglab',
                            style: TextStyle(
                              color: telegramBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: telegramBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        launcher.launchOrCopy(
                          context,
                          AppConstants.telegramUrl,
                          title: 'Telegram Channel',
                        );
                      },
                      child: const Text('Join', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Channel 2: TikTok
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: tikTokPink.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tikTokPink.withOpacity(0.20),
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: tikTokPink,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TikTok Showcase',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '@professor0011110',
                            style: TextStyle(
                              color: tikTokPink,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: tikTokPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        launcher.launchOrCopy(
                          context,
                          AppConstants.tiktokUrl,
                          title: 'TikTok Profile',
                        );
                      },
                      child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Dismiss action - opens How to Use guide for new users
              GlassButton.label(
                label: 'Continue to Laboratory',
                variant: GlassButtonVariant.glass,
                onPressed: () {
                  Navigator.of(context).pop();
                  HowToUseDialog.showIfFirstLaunch(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
