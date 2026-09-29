import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_section.dart';
import '../../../diagnostics/data/providers/full_device_info_provider.dart';
import '../../../optimization/domain/tweak_catalog.dart';
import '../../../optimization/presentation/providers/tweak_providers.dart';
import '../../../optimization/presentation/widgets/tweak_widgets.dart';

/// Internal storage usage with a measured cache cleanup.
class StorageCleanerWidget extends ConsumerWidget {
  const StorageCleanerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storage = ref.watch(fullDeviceInfoProvider).valueOrNull?.storage;
    final snapshot = ref.watch(tweaksControllerProvider).valueOrNull;
    final busy = snapshot?.isBusy(TweakCatalog.trimCaches.id) ?? false;
    final shizuku = snapshot?.capabilities.shizukuReady ?? false;

    final total = storage?.internalTotalGb;
    final avail = storage?.internalAvailableGb;
    final hasData = total != null && avail != null && total > 0;
    final used = hasData ? (total - avail).clamp(0.0, total) : 0.0;
    final ratio = hasData ? used / total : 0.0;
    final color = ratio > 0.9
        ? theme.colorScheme.error
        : ratio > 0.75
            ? const Color(0xFFF59E0B)
            : theme.colorScheme.primary;

    return GlassCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconTile(icon: Icons.sd_storage_rounded, color: color, size: 32),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text('Storage', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(
                hasData ? '${(ratio * 100).round()}% used' : '—',
                style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(value: ratio, minHeight: 8, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            hasData
                ? '${used.toStringAsFixed(1)} GB of ${total.toStringAsFixed(0)} GB · ${avail.toStringAsFixed(1)} GB free'
                : 'Storage info unavailable',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  shizuku
                      ? 'Clears cached files of every app. Measured after cleanup.'
                      : 'Without Shizuku only this app\'s cache can be cleared.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: busy
                    ? null
                    : () async {
                        final res = await ref
                            .read(tweaksControllerProvider.notifier)
                            .runAction(TweakCatalog.trimCaches.id);
                        ref.invalidate(fullDeviceInfoProvider);
                        if (context.mounted) showTweakResult(context, res);
                      },
                icon: busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cleaning_services_rounded, size: 18),
                label: const Text('Clean'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
