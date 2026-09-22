import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/about_config.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../providers/about_provider.dart';

class OpenSourcePackage {
  const OpenSourcePackage({
    required this.name,
    required this.author,
    required this.license,
    required this.description,
  });

  final String name;
  final String author;
  final String license;
  final String description;
}

const List<OpenSourcePackage> kOpenSourceDependencies = [
  OpenSourcePackage(
    name: 'Flutter SDK',
    author: 'Google LLC',
    license: 'BSD-3-Clause',
    description: 'Cross-platform UI toolkit and reactive framework',
  ),
  OpenSourcePackage(
    name: 'Flutter Riverpod',
    author: 'Remi Rousselet',
    license: 'MIT',
    description: 'Reactive state caching and dependency injection engine',
  ),
  OpenSourcePackage(
    name: 'GoRouter',
    author: 'Flutter Team',
    license: 'BSD-3-Clause',
    description: 'Declarative routing and navigation system',
  ),
  OpenSourcePackage(
    name: 'Shared Preferences',
    author: 'Flutter Team',
    license: 'BSD-3-Clause',
    description: 'Local platform key-value persistent storage',
  ),
  OpenSourcePackage(
    name: 'Package Info Plus',
    author: 'Flutter Community',
    license: 'BSD-3-Clause',
    description: 'Application package version and build telemetry',
  ),
  OpenSourcePackage(
    name: 'Google Fonts',
    author: 'Google LLC',
    license: 'Apache 2.0 / OFL',
    description: 'Modern typography typefaces (Inter and Outfit)',
  ),
  OpenSourcePackage(
    name: 'Flutter SVG',
    author: 'Dan Field',
    license: 'MIT',
    description: 'Scalable vector graphics rendering for Flutter',
  ),
];

/// Bottom sheet displaying open-source package dependencies and licenses.
class AcknowledgementsSheet extends ConsumerWidget {
  const AcknowledgementsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AcknowledgementsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(aboutConfigProvider);
    final appInfo = ref.watch(appInfoProvider).valueOrNull;

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.source_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Open-Source Licenses',
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
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: kOpenSourceDependencies.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final pkg = kOpenSourceDependencies[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pkg.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: AppRadius.radiusSm,
                                ),
                                child: Text(
                                  pkg.license,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Author: ${pkg.author}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pkg.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('View Full License Texts'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          showLicensePage(
                            context: context,
                            applicationName: config.appName,
                            applicationVersion:
                                appInfo?.versionDisplay ?? '1.0.0',
                            applicationLegalese: config.copyrightDisplay,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
}
