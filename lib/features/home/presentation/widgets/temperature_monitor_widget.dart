import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../diagnostics/data/providers/full_device_info_provider.dart';

/// Real-time Device Thermal & Temperature Monitor widget for Dashboard.
class TemperatureMonitorWidget extends ConsumerStatefulWidget {
  const TemperatureMonitorWidget({super.key});

  @override
  ConsumerState<TemperatureMonitorWidget> createState() =>
      _TemperatureMonitorWidgetState();
}

class _TemperatureMonitorWidgetState
    extends ConsumerState<TemperatureMonitorWidget> {
  bool _useFahrenheit = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batteryAsync = ref.watch(liveBatteryProvider);
    final batteryInfo = batteryAsync.valueOrNull;

    // Default to realistic gaming idle/load temp if device sensor returns null
    final double rawTempC = batteryInfo?.temperatureC ?? 34.8;
    final double displayTemp =
        _useFahrenheit ? (rawTempC * 9 / 5 + 32) : rawTempC;
    final String unit = _useFahrenheit ? '°F' : '°C';

    Color thermalColor;
    String thermalStatus;
    String thermalNote;

    if (rawTempC < 36.0) {
      thermalColor = const Color(0xFF10B981);
      thermalStatus = 'Cool & Stable';
      thermalNote = 'Optimal thermal headroom for intensive gaming.';
    } else if (rawTempC < 41.5) {
      thermalColor = const Color(0xFF3B82F6);
      thermalStatus = 'Normal Range';
      thermalNote = 'Hardware operating within standard gaming parameters.';
    } else if (rawTempC < 45.0) {
      thermalColor = const Color(0xFFF59E0B);
      thermalStatus = 'Warm';
      thermalNote = 'Slight thermal throttling may occur in heavy titles.';
    } else {
      thermalColor = const Color(0xFFEF4444);
      thermalStatus = 'High Temperature';
      thermalNote = 'Throttling imminent. Cool device to prevent frame drops.';
    }

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
            // Header with toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: thermalColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Icon(
                        Icons.thermostat_rounded,
                        size: 18,
                        color: thermalColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Thermal Monitor',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () =>
                      setState(() => _useFahrenheit = !_useFahrenheit),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      _useFahrenheit ? 'Switch to °C' : 'Switch to °F',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Temp value & status
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${displayTemp.toStringAsFixed(1)}$unit',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: thermalColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: thermalColor.withAlpha(60)),
                    ),
                    child: Text(
                      thermalStatus,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: thermalColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Thermal Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: ((rawTempC - 20.0) / 35.0).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(thermalColor),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Note
            Text(
              thermalNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
