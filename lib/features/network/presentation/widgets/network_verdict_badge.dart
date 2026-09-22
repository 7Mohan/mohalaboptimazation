import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../domain/entities/gaming_network_verdict.dart';

/// Prominent card badge rendering the primary gaming network verdict with icon and description.
class NetworkVerdictBadge extends StatelessWidget {
  const NetworkVerdictBadge({
    super.key,
    required this.verdict,
    this.secondaryVerdicts = const [],
  });

  final GamingNetworkVerdict verdict;
  final List<GamingNetworkVerdict> secondaryVerdicts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: verdict.color.withOpacity(0.12),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: verdict.color.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(verdict.icon, size: 22, color: verdict.color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  verdict.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: verdict.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            verdict.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          if (secondaryVerdicts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: secondaryVerdicts.map((v) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: v.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: v.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(v.icon, size: 12, color: v.color),
                      const SizedBox(width: 4),
                      Text(
                        v.title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: v.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
