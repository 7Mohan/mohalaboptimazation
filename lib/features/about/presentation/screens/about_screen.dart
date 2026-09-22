import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/about_config.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/about_provider.dart';
import '../widgets/acknowledgements_sheet.dart';
import '../widgets/announcements_feed.dart';
import '../widgets/changelog_dialog.dart';
import '../widgets/community_card.dart';
import '../widgets/legal_document_dialog.dart';
import '../widgets/ownership_notice_card.dart';
import '../../../community/presentation/widgets/startup_community_dialog.dart';
import '../../../onboarding/presentation/widgets/how_to_use_dialog.dart';

/// Polished About screen presenting product details, developer info,
/// Telegram community entry point, legal policies, and clear ownership notice.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = ref.watch(aboutConfigProvider);
    final launcher = ref.watch(urlLauncherServiceProvider);
    final appInfoAsync = ref.watch(appInfoProvider);

    return Scaffold(
      appBar: const MohaAppBar(
        title: 'About',
        showBrand: false,
        subtitle: 'Product details, community & legal notices',
      ),
      body: ListView(
        padding: AppSpacing.screenContentPadding,
        children: [
          // ── Brand Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primaryContainer,
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: AppSizes.iconXl,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  config.brandName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Optimization',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const MohaStatusBadge(
                  type: MohaStatusType.safe,
                  customLabel: 'Android Utility Edition',
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  config.tagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ── Quick Links Bar ─────────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickLinkButton(
                    icon: Icons.language_rounded,
                    label: 'Website',
                    onTap: () => launcher.launchOrCopy(
                      context,
                      config.websiteUrl,
                      title: 'Website',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _QuickLinkButton(
                    icon: Icons.send_rounded,
                    label: 'Telegram',
                    onTap: () => launcher.launchOrCopy(
                      context,
                      config.telegramCommunityUrl,
                      title: 'Telegram Community',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _QuickLinkButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'TikTok',
                    onTap: () => launcher.launchOrCopy(
                      context,
                      config.tiktokCommunityUrl,
                      title: 'TikTok Profile',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _QuickLinkButton(
                    icon: Icons.email_outlined,
                    label: 'Contact',
                    onTap: () => launcher.launchOrCopy(
                      context,
                      'mailto:${config.contactEmail}',
                      title: 'Support Email',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Announcements & Telegram Feed ────────────────────────────────────
          const AnnouncementsFeedWidget(),

          const SizedBox(height: AppSpacing.lg),

          // ── Community Section ───────────────────────────────────────────────
          const SectionHeader(
            title: 'Community',
            subtitle: 'Connect with fellow gamers and project contributors.',
            icon: Icons.groups_outlined,
          ),
          const CommunityCard(),

          const SizedBox(height: AppSpacing.lg),

          // ── Application Telemetry & Build Info ──────────────────────────────
          appInfoAsync.when(
            loading: () => const InfoCard(
              title: 'APP INFO',
              children: [
                InfoRow(label: 'Version', value: '—'),
                InfoRow(label: 'Build', value: '—'),
                InfoRow(label: 'Package', value: '—'),
              ],
            ),
            error: (_, __) => const InfoCard(
              title: 'APP INFO',
              children: [
                InfoRow(label: 'Version', value: '1.0.0'),
                InfoRow(label: 'Build', value: '1'),
                InfoRow(label: 'Package', value: 'com.mohalab.optimization'),
              ],
            ),
            data: (info) => InfoCard(
              title: 'APP INFO',
              children: [
                InfoRow(label: 'Version', value: info.version),
                InfoRow(label: 'Build', value: info.buildNumber),
                InfoRow(label: 'Package', value: info.packageName),
                const InfoRow(
                  label: 'Architecture',
                  value: 'Flutter & Kotlin Native',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Developer Information ───────────────────────────────────────────
          InfoCard(
            title: 'DEVELOPER & CONTACT',
            children: [
              InfoRow(
                label: 'Developer',
                value: config.developerName,
              ),
              InfoRow(
                label: 'Support',
                value: config.contactEmail,
              ),
              InfoRow(
                label: 'Official Site',
                value: config.websiteUrl,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Legal & Transparency ────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('Release Notes & Changelog',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Version 2.0.0 features & update history'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => ChangelogDialog.show(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('How to Use Moha Lab',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Interactive feature walkthrough & setup tips'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => HowToUseDialog.showExplicit(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.celebration_outlined),
                  title: const Text('Welcome Dialog',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Re-open first-launch community greeting'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => StartupCommunityDialog.showExplicit(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Local-first storage & telemetry transparency'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => LegalDocumentDialog.show(
                    context,
                    LegalDocumentType.privacyPolicy,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Terms of Service',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Personal use terms and safety disclosures'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => LegalDocumentDialog.show(
                    context,
                    LegalDocumentType.termsOfService,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.source_outlined),
                  title: const Text('Open-Source Licenses',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View third-party packages & license notices'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => AcknowledgementsSheet.show(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Acknowledgements (Retained for test compliance) ─────────────────
          const InfoCard(
            title: 'ACKNOWLEDGEMENTS',
            children: [
              _AcknowledgementRow(
                name: 'Flutter',
                description: 'UI toolkit by Google',
              ),
              _AcknowledgementRow(
                name: 'Riverpod',
                description: 'State management by Remi Rousselet',
              ),
              _AcknowledgementRow(
                name: 'GoRouter',
                description: 'Declarative routing for Flutter',
              ),
              _AcknowledgementRow(
                name: 'Google Fonts',
                description: 'Outfit and Inter typefaces',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Ownership Notice Card ───────────────────────────────────────────
          const OwnershipNoticeCard(),

          const SizedBox(height: AppSpacing.lg),

          // ── Footer Copyright ────────────────────────────────────────────────
          Center(
            child: Text(
              config.copyrightDisplay,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  const _QuickLinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: AppRadius.radiusMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcknowledgementRow extends StatelessWidget {
  const _AcknowledgementRow({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$name — ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: description,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
