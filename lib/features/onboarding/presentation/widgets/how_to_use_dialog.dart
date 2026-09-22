import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../../settings/presentation/providers/theme_provider.dart';
import '../../../shizuku/presentation/providers/shizuku_provider.dart';

const _kHowToUseSeenKey = 'has_seen_how_to_use_guide_v1';

/// Interactive "How to Use Moha Lab" Guide for new users.
class HowToUseDialog extends ConsumerStatefulWidget {
  const HowToUseDialog({super.key});

  /// Displays the dialog if it has not been seen before.
  static Future<void> showIfFirstLaunch(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final hasSeen = prefs.getBool(_kHowToUseSeenKey) ?? false;
      if (!hasSeen && context.mounted) {
        await prefs.setBool(_kHowToUseSeenKey, true);
        if (context.mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: true,
            barrierColor: Colors.black.withOpacity(0.70),
            builder: (ctx) => const HowToUseDialog(),
          );
        }
      }
    } catch (_) {}
  }

  /// Explicitly show the guide from Settings or About
  static Future<void> showExplicit(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.70),
      builder: (ctx) => const HowToUseDialog(),
    );
  }

  @override
  ConsumerState<HowToUseDialog> createState() => _HowToUseDialogState();
}

class _HowToUseDialogState extends ConsumerState<HowToUseDialog> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_GuideStepData> _steps = const [
    _GuideStepData(
      stepNumber: 'STEP 1',
      badge: 'CORE ENGINE',
      badgeColor: Color(0xFF1E56DE),
      title: 'Power Up with Shizuku',
      subtitle: 'Zero-Root Deep System Access',
      icon: Icons.bolt_rounded,
      accentColor: Color(0xFF3B82F6),
      summary:
          'Moha Lab uses Shizuku to safely modify privileged Android system settings without rooting your device.',
      highlights: [
        'Enables 2x faster 0.5x window animations',
        'Direct system-wide cache trim & RAM cleanup',
        'Display refresh rate locking to 90Hz / 120Hz',
      ],
      actionLabel: 'Check Shizuku Status',
    ),
    _GuideStepData(
      stepNumber: 'STEP 2',
      badge: 'PERFORMANCE',
      badgeColor: Color(0xFF10B981),
      title: 'Choose Your Optimization Profile',
      subtitle: 'Instant Hardware Adaptation',
      icon: Icons.speed_rounded,
      accentColor: Color(0xFF10B981),
      summary:
          'Switch between 3 pre-engineered profiles tailored to your current scenario with one tap.',
      highlights: [
        'Battery Saver: Throttles unnecessary animations to extend battery life',
        'Balanced: Optimal responsiveness for daily multitasking',
        'Beast Mode: Peak frame rates & cleared RAM for demanding games',
      ],
      actionLabel: 'Explore Profiles',
    ),
    _GuideStepData(
      stepNumber: 'STEP 3',
      badge: 'GAMING LAB',
      badgeColor: Color(0xFF8B5CF6),
      title: 'Per-Game Custom Presets',
      subtitle: 'Individual Game Tuning & Launch',
      icon: Icons.sports_esports_rounded,
      accentColor: Color(0xFF8B5CF6),
      summary:
          'Auto-detects your installed games and lets you configure custom presets for each title.',
      highlights: [
        'Set specific target refresh rates per game',
        'One-tap "Boost & Launch" directly from your Games hub',
        'Tracks play session duration and performance statistics',
      ],
      actionLabel: 'Go to Games Lab',
    ),
    _GuideStepData(
      stepNumber: 'STEP 4',
      badge: 'AUTOMATION',
      badgeColor: Color(0xFFF59E0B),
      title: 'Live Telemetry & Schedules',
      subtitle: 'Hands-Free Maintenance',
      icon: Icons.schedule_rounded,
      accentColor: Color(0xFFF59E0B),
      summary:
          'Monitor hardware vitals in real time and schedule automatic background maintenance.',
      highlights: [
        'Real-time core frequencies & thermal sensor charts',
        'One-tap junk storage & residual cache cleaner',
        'Set daily auto-cleanup to keep your device smooth forever',
      ],
      actionLabel: 'Start Using Moha Lab',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleStepAction(int index) {
    Navigator.of(context).pop();
    switch (index) {
      case 0:
        context.go(RouteNames.optimization);
        ref.read(shizukuServiceProvider).requestPermission();
        break;
      case 1:
        context.go(RouteNames.optimization);
        break;
      case 2:
        context.go(RouteNames.games);
        break;
      case 3:
        context.go(RouteNames.home);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLastStep = _currentIndex == _steps.length - 1;
    final currentStep = _steps[_currentIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: GlassCard(
        level: AppGlassLevel.level4,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentStep.accentColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentStep.stepNumber,
                          style: TextStyle(
                            color: currentStep.accentColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MohaStatusBadge(
                        type: MohaStatusType.safe,
                        customLabel: currentStep.badge,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Step Carousel
              SizedBox(
                height: 340,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemBuilder: (context, idx) {
                    final step = _steps[idx];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: step.accentColor.withOpacity(0.20),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: step.accentColor.withOpacity(0.50),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                step.icon,
                                color: step.accentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Text(
                                    step.subtitle,
                                    style: TextStyle(
                                      color: step.accentColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        Text(
                          step.summary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Highlight Points
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.02),
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(
                              color: step.accentColor.withOpacity(0.30),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: step.highlights.map((h) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: step.accentColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        h,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Page Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? currentStep.accentColor
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Direct Action Button for current step
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: currentStep.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () => _handleStepAction(_currentIndex),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  currentStep.actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Next / Close Step button
              GlassButton.label(
                label: isLastStep ? 'Ready! Explore Lab' : 'Next Step (${_currentIndex + 2}/${_steps.length})',
                variant: GlassButtonVariant.glass,
                onPressed: _onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideStepData {
  const _GuideStepData({
    required this.stepNumber,
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.summary,
    required this.highlights,
    required this.actionLabel,
  });

  final String stepNumber;
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String summary;
  final List<String> highlights;
  final String actionLabel;
}
