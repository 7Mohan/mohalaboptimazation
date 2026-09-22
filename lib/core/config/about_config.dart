import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// Configuration for the About screen, community links, developer details,
/// and ownership notices.
///
/// Designed to be configuration-driven so that URLs and contact information
/// can be updated without rewriting the UI.
class AboutConfig {
  const AboutConfig({
    this.brandName = AppConstants.brandName,
    this.appName = AppConstants.appName,
    this.tagline = 'Safe, transparent gaming performance & network diagnostics for Android',
    this.developerName = 'Moha Lab Team',
    this.contactEmail = AppConstants.supportEmail,
    this.websiteUrl = AppConstants.websiteUrl,
    this.telegramCommunityUrl = AppConstants.telegramUrl,
    this.telegramCommunityHandle = '@Mohagaminglab',
    this.tiktokCommunityUrl = AppConstants.tiktokUrl,
    this.tiktokCommunityHandle = '@professor0011110',
    this.githubUrl = 'https://github.com/mohalab',
    this.privacyPolicyUrl = 'https://mohalab.dev/privacy',
    this.termsOfServiceUrl = 'https://mohalab.dev/terms',
    this.copyrightOwner = 'Moha Lab',
    this.copyrightYear = '2024–2026',
    this.ownershipNotice =
        'Moha Lab Optimization, including its user interface design, visual branding, '
        'graphics, custom algorithms, and original content, is the intellectual property of Moha Lab. '
        'All rights reserved. Third-party open-source libraries and frameworks remain the property '
        'of their respective authors and are used in compliance with their open-source licenses.',
  });

  /// The overarching brand title (e.g., "MOHA LAB").
  final String brandName;

  /// The full application title (e.g., "Moha Lab Optimization").
  final String appName;

  /// Short product description.
  final String tagline;

  /// Developer / Publisher name.
  final String developerName;

  /// Contact & support email address.
  final String contactEmail;

  /// Official product website URL.
  final String websiteUrl;

  /// Telegram community invite URL.
  final String telegramCommunityUrl;

  /// Telegram community handle or display name.
  final String telegramCommunityHandle;

  /// TikTok community invite URL.
  final String tiktokCommunityUrl;

  /// TikTok community handle or display name.
  final String tiktokCommunityHandle;

  /// Project source or organization repository URL.
  final String githubUrl;

  /// Privacy policy web URL.
  final String privacyPolicyUrl;

  /// Terms of service web URL.
  final String termsOfServiceUrl;

  /// Legal copyright holder.
  final String copyrightOwner;

  /// Copyright year range.
  final String copyrightYear;

  /// Ownership notice and intellectual property statement.
  final String ownershipNotice;

  /// Formatted copyright string.
  String get copyrightDisplay => '© $copyrightYear $copyrightOwner. All rights reserved.';

  /// Validates whether a given URL string is non-empty and well-formed.
  static bool isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'mailto' || uri.scheme == 'tg');
  }

  /// Creates a copy of this configuration with optional overrides.
  AboutConfig copyWith({
    String? brandName,
    String? appName,
    String? tagline,
    String? developerName,
    String? contactEmail,
    String? websiteUrl,
    String? telegramCommunityUrl,
    String? telegramCommunityHandle,
    String? tiktokCommunityUrl,
    String? tiktokCommunityHandle,
    String? githubUrl,
    String? privacyPolicyUrl,
    String? termsOfServiceUrl,
    String? copyrightOwner,
    String? copyrightYear,
    String? ownershipNotice,
  }) {
    return AboutConfig(
      brandName: brandName ?? this.brandName,
      appName: appName ?? this.appName,
      tagline: tagline ?? this.tagline,
      developerName: developerName ?? this.developerName,
      contactEmail: contactEmail ?? this.contactEmail,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      telegramCommunityUrl: telegramCommunityUrl ?? this.telegramCommunityUrl,
      telegramCommunityHandle: telegramCommunityHandle ?? this.telegramCommunityHandle,
      tiktokCommunityUrl: tiktokCommunityUrl ?? this.tiktokCommunityUrl,
      tiktokCommunityHandle: tiktokCommunityHandle ?? this.tiktokCommunityHandle,
      githubUrl: githubUrl ?? this.githubUrl,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      termsOfServiceUrl: termsOfServiceUrl ?? this.termsOfServiceUrl,
      copyrightOwner: copyrightOwner ?? this.copyrightOwner,
      copyrightYear: copyrightYear ?? this.copyrightYear,
      ownershipNotice: ownershipNotice ?? this.ownershipNotice,
    );
  }
}

/// Riverpod provider supplying the [AboutConfig]. Can be overridden in tests
/// or customized per build flavor.
final aboutConfigProvider = Provider<AboutConfig>((ref) {
  return const AboutConfig();
});
