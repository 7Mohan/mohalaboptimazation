import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../domain/entities/network_connection_type.dart';
import '../../domain/entities/network_metrics.dart';

/// Card showing current active network transport and interface properties.
class NetworkOverviewCard extends StatelessWidget {
  const NetworkOverviewCard({
    super.key,
    required this.metrics,
  });

  final NetworkMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connType = metrics?.connectionType ?? NetworkConnectionType.unknown;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Icon(
                    connType.icon,
                    size: AppSizes.iconMd,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connType.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        connType.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (metrics?.wifiBandDisplay != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadius.radiusSm,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      metrics!.wifiBandDisplay!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            if (metrics?.wifiLinkSpeedMbps != null || metrics?.localGatewayLatencyMs != null) ...[
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (metrics?.wifiLinkSpeedMbps != null)
                    _MetaItem(
                      label: 'Link Speed',
                      value: '${metrics!.wifiLinkSpeedMbps} Mbps',
                    ),
                  if (metrics?.localGatewayLatencyMs != null)
                    _MetaItem(
                      label: 'Gateway Ping',
                      value: '${metrics!.localGatewayLatencyMs!.toStringAsFixed(1)} ms',
                    ),
                  _MetaItem(
                    label: 'Status',
                    value: (metrics?.isOnline ?? false) ? 'Connected' : 'Offline',
                    isPositive: metrics?.isOnline ?? false,
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.label,
    required this.value,
    this.isPositive,
  });

  final String label;
  final String value;
  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valColor = isPositive == null
        ? theme.colorScheme.onSurface
        : (isPositive! ? Colors.green : Colors.red);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valColor,
          ),
        ),
      ],
    );
  }
}
