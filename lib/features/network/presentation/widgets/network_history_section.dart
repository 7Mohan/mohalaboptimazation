import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../domain/entities/network_diagnostic_session.dart';
import '../providers/network_diagnostics_providers.dart';

/// Renders historical diagnostic sessions with metrics summaries and deletion controls.
class NetworkHistorySection extends ConsumerWidget {
  const NetworkHistorySection({
    super.key,
    required this.history,
  });

  final List<NetworkDiagnosticSession> history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (history.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 36,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'No past test runs recorded',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Tests (${history.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(networkDiagnosticsControllerProvider.notifier)
                        .clearHistory();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) {
              final session = history[index];
              return ListTile(
                dense: true,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: session.primaryVerdict.color.withOpacity(0.12),
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Icon(
                    session.primaryVerdict.icon,
                    size: 18,
                    color: session.primaryVerdict.color,
                  ),
                ),
                title: Text(
                  session.primaryVerdict.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${session.metrics.connectionType.displayName} • Ping: ${session.metrics.latencyDisplay} • Jitter: ${session.metrics.jitterDisplay}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  tooltip: 'Delete run',
                  onPressed: () {
                    ref
                        .read(networkDiagnosticsControllerProvider.notifier)
                        .deleteSession(session.id);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
