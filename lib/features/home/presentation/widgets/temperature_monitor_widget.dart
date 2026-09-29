import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_section.dart';
import '../../../diagnostics/data/providers/full_device_info_provider.dart';

/// Battery temperature plus Android's own thermal verdict.
///
/// Temperature comes from the battery sensor; the status and throttling
/// forecast come from PowerManager (API 29/30+). Nothing is estimated — if a
/// source is missing the card says so.
class TemperatureMonitorWidget extends ConsumerStatefulWidget {
  const TemperatureMonitorWidget({super.key});

  @override
  ConsumerState<TemperatureMonitorWidget> createState() => _TemperatureMonitorWidgetState();
}

class _TemperatureMonitorWidgetState extends ConsumerState<TemperatureMonitorWidget> {
  bool _useFahrenheit = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tempC = ref.watch(liveBatteryProvider).valueOrNull?.temperatureC;
    final thermal = ref.watch(liveThermalProvider).valueOrNull;
    final headroom = thermal?.headroom;

    final Color color;
    final String verdict;
    final status = thermal?.status;
    if (status != null && status >= 3 || (headroom != null && headroom >= 0.95)) {
      color = AppColors.error;
      verdict = 'Throttling';
    } else if (status != null && status >= 1 || (headroom != null && headroom >= 0.75)) {
      color = AppColors.warning;
      verdict = 'Warm';
    } else if (tempC == null && status == null) {
      color = theme.colorScheme.onSurfaceVariant;
      verdict = 'No sensor';
    } else {
      color = theme.colorScheme.tertiary;
      verdict = 'Cool';
    }

    final display = tempC == null
        ? '—'
        : _useFahrenheit
            ? '${(tempC * 9 / 5 + 32).toStringAsFixed(1)}°F'
            : '${tempC.toStringAsFixed(1)}°C';

    return GlassCard(
      padding: AppSpacing.cardPadding,
      onTap: tempC == null ? null : () => setState(() => _useFahrenheit = !_useFahrenheit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconTile(icon: Icons.thermostat_rounded, color: color, size: 32),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text('Thermals', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(display, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
          Text(
            thermal?.statusLabel != null ? '$verdict · status ${thermal!.statusLabel}' : '$verdict · battery sensor',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Throttle headroom',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: headroom?.clamp(0.0, 1.0) ?? 0,
              minHeight: 6,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            headroom == null ? 'Forecast needs Android 11+' : '${(headroom * 100).round()}% of throttle point in 10 s',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
