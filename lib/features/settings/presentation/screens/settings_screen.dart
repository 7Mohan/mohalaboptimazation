import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/services/moha_notification_service.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/theme_preference.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/settings/moha_settings_tile.dart';
import '../providers/app_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? const AppSettings();

    return Scaffold(
      appBar: const MohaAppBar(
        title: 'Settings',
        subtitle: 'Preferences and data management',
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // ── Appearance ──────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Appearance',
            subtitle: 'Choose how the app looks on your device.',
            icon: Icons.palette_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: ThemePreference.values
                    .asMap()
                    .entries
                    .map((entry) => RadioListTile<ThemePreference>(
                          value: entry.value,
                          groupValue: settings.theme,
                          title: Text(
                            entry.value.label,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          secondary: _IconBox(
                            icon: _iconForTheme(entry.value),
                            isActive: entry.value == settings.theme,
                          ),
                          activeColor: theme.colorScheme.primary,
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .update((s) => s.copyWith(theme: v));
                            }
                          },
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Language ────────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Language',
            subtitle: 'UI language selection.',
            icon: Icons.language_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: LanguagePreference.values
                    .asMap()
                    .entries
                    .map((entry) => RadioListTile<LanguagePreference>(
                          value: entry.value,
                          groupValue: settings.language,
                          title: Text(entry.value.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600)),
                          activeColor: theme.colorScheme.primary,
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .update((s) => s.copyWith(language: v));
                            }
                          },
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Notifications ───────────────────────────────────────────────────
          const SectionHeader(
            title: 'Notifications',
            subtitle: 'Control in-app banners and alerts.',
            icon: Icons.notifications_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: settings.notificationsEnabled,
                    onChanged: (v) => ref
                        .read(appSettingsProvider.notifier)
                        .update((s) => s.copyWith(notificationsEnabled: v)),
                    title: const Text('In-App Notifications',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'Show banners when optimizations complete or diagnostics finish'),
                    secondary: const _IconBox(
                        icon: Icons.notifications_active_outlined, isActive: true),
                    activeColor: Theme.of(context).colorScheme.primary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMd),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const _IconBox(
                      icon: Icons.notification_add_outlined,
                      isActive: false,
                    ),
                    title: const Text(
                      'Test Optimization Notification',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Sends an instant local notification sample',
                    ),
                    trailing: const Icon(Icons.send_rounded, size: 20),
                    onTap: () async {
                      await ref
                          .read(notificationServiceProvider)
                          .showOptimizationReminder(
                            title: 'Moha Lab Tuning Reminder',
                            body:
                                'RAM cache is above 75%. Run a quick optimization before your next gaming session.',
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification dispatched! Check your notification shade.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Optimization Behaviour ──────────────────────────────────────────
          const SectionHeader(
            title: 'Default Optimization Behaviour',
            subtitle: 'What happens when you start an optimization session.',
            icon: Icons.tune_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: DefaultOptimizationBehaviour.values
                    .asMap()
                    .entries
                    .map((entry) => RadioListTile<DefaultOptimizationBehaviour>(
                          value: entry.value,
                          groupValue: settings.defaultOptimizationBehaviour,
                          title: Text(entry.value.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(entry.value.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          activeColor: theme.colorScheme.primary,
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .update((s) => s.copyWith(
                                      defaultOptimizationBehaviour: v));
                            }
                          },
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Performance Monitoring ──────────────────────────────────────────
          const SectionHeader(
            title: 'Performance Monitoring',
            subtitle: 'Controls background metric sampling frequency.',
            icon: Icons.monitor_heart_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: PerformanceMonitoringMode.values
                    .asMap()
                    .entries
                    .map((entry) => RadioListTile<PerformanceMonitoringMode>(
                          value: entry.value,
                          groupValue: settings.performanceMonitoringMode,
                          title: Text(entry.value.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(entry.value.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          activeColor: theme.colorScheme.primary,
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .update((s) => s.copyWith(
                                      performanceMonitoringMode: v));
                            }
                          },
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Network Test ────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Network Diagnostics',
            subtitle: 'When to automatically run a network test.',
            icon: Icons.network_check_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: NetworkTestAutoRun.values
                    .asMap()
                    .entries
                    .map((entry) => RadioListTile<NetworkTestAutoRun>(
                          value: entry.value,
                          groupValue: settings.networkTestAutoRun,
                          title: Text(entry.value.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(entry.value.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          activeColor: theme.colorScheme.primary,
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .update((s) =>
                                      s.copyWith(networkTestAutoRun: v));
                            }
                          },
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Privacy ─────────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Privacy',
            subtitle: 'Your data, explained clearly.',
            icon: Icons.lock_outline,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              children: [
                // Privacy disclosure card
                Card(
                  color: theme.colorScheme.primaryContainer.withAlpha(70),
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.verified_user_outlined,
                              color: theme.colorScheme.primary, size: AppSizes.iconMd),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Your Data, Your Device',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: AppSpacing.sm),
                        const _PrivacyPoint(
                          icon: Icons.account_circle_outlined,
                          text: 'No account is required to use this app.',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const _PrivacyPoint(
                          icon: Icons.storage_outlined,
                          text:
                              'Your game profiles and diagnostic history are stored locally on this device only.',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const _PrivacyPoint(
                          icon: Icons.cloud_off_outlined,
                          text:
                              'This app does not connect to any external analytics or advertising service.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Crash reporting opt-in
                Card(
                  child: SwitchListTile(
                    value: settings.crashReportingOptIn,
                    onChanged: (v) => ref
                        .read(appSettingsProvider.notifier)
                        .update((s) => s.copyWith(crashReportingOptIn: v)),
                    title: const Text('Crash Reporting (Opt-In)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'If enabled in a future update, anonymous crash logs may be collected. '
                        'Currently disabled — no data is sent.'),
                    secondary: const _IconBox(
                        icon: Icons.bug_report_outlined, isActive: false),
                    activeColor: theme.colorScheme.primary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMd),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Safety ──────────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Safety',
            subtitle: 'Immutable safety guarantees.',
            icon: Icons.security_rounded,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: [
                  const MohaSettingsTile(
                    title: 'Safe Mode Enforcement',
                    subtitle:
                        'Elevated system changes always require explicit confirmation',
                    leadingIcon: Icons.verified_user_outlined,
                    trailing: MohaStatusBadge(
                        type: MohaStatusType.safe, customLabel: 'Enforced'),
                    onTap: null,
                    showDivider: true,
                  ),
                  MohaSettingsTile(
                    title: 'Reset Settings to Defaults',
                    subtitle: 'Restores all preferences (not profiles or history)',
                    leadingIcon: Icons.settings_backup_restore_outlined,
                    onTap: () => _confirmResetSettings(context, ref),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Data Management ─────────────────────────────────────────────────
          const SectionHeader(
            title: 'Data Management',
            subtitle: 'Export, import, or clear your local data.',
            icon: Icons.folder_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: [
                  MohaSettingsTile(
                    title: 'Manage Local Data',
                    subtitle: 'Export, import, clear history and profiles',
                    leadingIcon: Icons.manage_history_outlined,
                    onTap: () => context.push(RouteNames.dataManagement),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Application ─────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Application',
            subtitle: 'Product info and build details.',
            icon: Icons.info_outline,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: [
                  MohaSettingsTile(
                    title: 'Tutorial & Feature Walkthrough',
                    subtitle: 'Replay the introductory onboarding tour',
                    leadingIcon: Icons.explore_outlined,
                    onTap: () => context.push(RouteNames.onboarding),
                    showDivider: true,
                  ),
                  MohaSettingsTile(
                    title: 'About Moha Lab Optimization',
                    subtitle: 'Version, licenses, and architecture overview',
                    leadingIcon: Icons.info_outline,
                    onTap: () => context.go(RouteNames.about),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetSettings(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
            'All preferences will return to their defaults. '
            'Your game profiles and history will not be affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(appSettingsProvider.notifier).reset();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  IconData _iconForTheme(ThemePreference pref) => switch (pref) {
        ThemePreference.system => Icons.brightness_auto_outlined,
        ThemePreference.light => Icons.light_mode_outlined,
        ThemePreference.dark => Icons.dark_mode_outlined,
        ThemePreference.amoled => Icons.contrast_outlined,
      };
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.isActive});
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Icon(
        icon,
        size: AppSizes.iconSm,
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(text,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface, height: 1.4)),
        ),
      ],
    );
  }
}
