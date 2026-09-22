import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/about_config.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';

enum LegalDocumentType {
  privacyPolicy,
  termsOfService,
}

/// In-app reader for legal documents (Privacy Policy and Terms of Service).
///
/// Ensures users can read complete, clear, and honest legal disclosures offline
/// without requiring an external browser, while also providing browser links.
class LegalDocumentDialog extends ConsumerWidget {
  const LegalDocumentDialog({
    super.key,
    required this.type,
  });

  final LegalDocumentType type;

  static void show(BuildContext context, LegalDocumentType type) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LegalDocumentDialog(type: type),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(aboutConfigProvider);
    final launcher = ref.watch(urlLauncherServiceProvider);

    final isPrivacy = type == LegalDocumentType.privacyPolicy;
    final title = isPrivacy ? 'Privacy Policy' : 'Terms of Service';
    final webUrl = isPrivacy ? config.privacyPolicyUrl : config.termsOfServiceUrl;
    final hasValidUrl = AboutConfig.isValidUrl(webUrl);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Sheet header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      isPrivacy
                          ? Icons.privacy_tip_outlined
                          : Icons.gavel_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Document content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (isPrivacy)
                      ..._buildPrivacySections(theme, config)
                    else
                      ..._buildTermsSections(theme, config),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (hasValidUrl) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                          label: const Text('Open Online'),
                          onPressed: () => launcher.launchOrCopy(
                            context,
                            webUrl,
                            title: title,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.outlined(
                        tooltip: 'Copy Link',
                        style: IconButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd,
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: webUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$title link copied!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMd,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPrivacySections(ThemeData theme, AboutConfig config) {
    return [
      _sectionHeader(theme, '1. Local-Only Storage'),
      _bodyText(
        theme,
        'Moha Lab Optimization is architected as a local-first utility. '
        'All application settings, custom game profiles, optimization preferences, '
        'and diagnostic logs are stored exclusively in your device\'s local storage. '
        'No user account, phone number, or email address is collected to use the application.',
      ),
      const SizedBox(height: AppSpacing.md),
      _sectionHeader(theme, '2. Third-Party Analytics & Tracking'),
      _bodyText(
        theme,
        'This software contains zero third-party advertising trackers or commercial surveillance SDKs. '
        'Diagnostic tests (such as ping, DNS timing, and socket connectivity) communicate strictly '
        'with standard internet endpoints (such as public DNS resolvers) to measure latency and packet '
        'loss without transmitting device fingerprints.',
      ),
      const SizedBox(height: AppSpacing.md),
      _sectionHeader(theme, '3. Elevated System Permissions'),
      _bodyText(
        theme,
        'Certain performance optimization features require elevated permissions via Shizuku '
        'or Android system settings. These capabilities are only utilized when you explicitly trigger '
        'an optimization action. Permissions are never shared, persisted externally, or used in the background '
        'without your active session.',
      ),
      const SizedBox(height: AppSpacing.md),
      _sectionHeader(theme, '4. Data Portability and Deletion'),
      _bodyText(
        theme,
        'You retain complete control over your data. You may export all configuration and history '
        'files to a standard JSON format, or permanently erase all stored profiles and cached history '
        'at any time via the Settings > Data Management screen.',
      ),
      const SizedBox(height: AppSpacing.md),
      _sectionHeader(theme, '5. Developer Inquiries'),
      _bodyText(
        theme,
        'If you have questions regarding this privacy disclosure, contact us at: '
        '${config.contactEmail}',
      ),
    ];
  }

  List<Widget> _buildTermsSections(ThemeData theme, AboutConfig config) {
    return [
      _sectionHeader(theme, '1. Acceptance of Terms'),
      _bodyText(
        theme,
        'By installing and running Moha Lab Optimization, you acknowledge and agree to these terms. '
        'This software is provided for personal use to help Android device owners monitor system '
        'telemetry and optimize their mobile gaming experience.',
      ),
      const SizedBox(height: AppSpacing.md),
      _sectionHeader(theme, '2. User Discretion and System Tweaks'),
      _bodyText(
        theme,
        'Moha Lab Optimization prioritizes safe, documented, and reversible Android operating system '
        'tweaks. However, hardware performance, thermals, and battery behaviors vary significantly '
        'across manufacturers and Android versions. You are responsible for reviewing proposed tweaks '
        'prior to execution.',
      ),
      const SizedBox(height: AppSpacing.md),
      _sectionHeader(theme, '3. Disclaimers and Limitations of Warranty'),
      _bodyText(
        theme,
        'The application is provided "as is", without warranty of any kind, express or implied. '
        'Moha Lab does not guarantee that using this utility will prevent game crashes or latency spikes '
        'caused by remote game servers or local hardware limitations.',
      ),
      const SizedBox(height: AppSpacing.md),
      _sectionHeader(theme, '4. Intellectual Property & License'),
      _bodyText(
        theme,
        'All rights in the original software, user interface design, logos, and custom assets are '
        'reserved by ${config.copyrightOwner}. You may not redistribute, reverse-engineer, or rebrand '
        'this software for commercial purposes without prior permission.',
      ),
    ];
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _bodyText(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.45,
      ),
    );
  }
}
