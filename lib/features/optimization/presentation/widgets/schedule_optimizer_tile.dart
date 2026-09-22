import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../data/services/optimization_scheduler.dart';

class ScheduleOptimizerTile extends ConsumerWidget {
  const ScheduleOptimizerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(optimizationSchedulerProvider);
    final notifier = ref.read(optimizationSchedulerProvider.notifier);

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
            // Switch header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(25),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Auto-Optimization',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Run performance sweeps automatically in the background',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: config.enabled,
                  onChanged: (val) => notifier.setEnabled(val),
                ),
              ],
            ),

            if (config.enabled) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Frequency Chips
              Text(
                'RUN FREQUENCY',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _IntervalChip(
                    label: 'Every 6 hrs',
                    selected: config.intervalHours == 6,
                    onTap: () => notifier.setIntervalHours(6),
                  ),
                  const SizedBox(width: 6),
                  _IntervalChip(
                    label: 'Every 12 hrs',
                    selected: config.intervalHours == 12,
                    onTap: () => notifier.setIntervalHours(12),
                  ),
                  const SizedBox(width: 6),
                  _IntervalChip(
                    label: 'Daily (24 hrs)',
                    selected: config.intervalHours == 24,
                    onTap: () => notifier.setIntervalHours(24),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Target Profile
              Text(
                'SCHEDULED PROFILE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _IntervalChip(
                    label: 'Balanced',
                    selected: config.profileId == 'balanced',
                    onTap: () => notifier.setProfile('balanced'),
                  ),
                  const SizedBox(width: 6),
                  _IntervalChip(
                    label: 'Extreme',
                    selected: config.profileId == 'extreme',
                    onTap: () => notifier.setProfile('extreme'),
                  ),
                  const SizedBox(width: 6),
                  _IntervalChip(
                    label: 'Battery Saver',
                    selected: config.profileId == 'battery_saver',
                    onTap: () => notifier.setProfile('battery_saver'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IntervalChip extends StatelessWidget {
  const _IntervalChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
