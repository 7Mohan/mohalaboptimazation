import 'package:flutter/material.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_card.dart';

class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ChangelogDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const releases = [
      _ReleaseInfo(
        version: 'v2.0.0 - Laboratory Evolution',
        date: 'September 2026',
        isLatest: true,
        changes: [
          _ChangeItem(type: _ChangeType.feature, text: 'Quad-level Glassmorphism design system & tactile feedback'),
          _ChangeItem(type: _ChangeType.feature, text: 'Balanced, Extreme, and Battery Saver optimization profiles'),
          _ChangeItem(type: _ChangeType.feature, text: 'Real-time CPU waveform monitor and storage cleaner widget'),
          _ChangeItem(type: _ChangeType.feature, text: 'Thermal throttling warning and battery temperature metrics'),
          _ChangeItem(type: _ChangeType.feature, text: 'Custom per-game presets and performance session tracker'),
          _ChangeItem(type: _ChangeType.feature, text: 'Scheduled background auto-optimization via Workmanager'),
          _ChangeItem(type: _ChangeType.feature, text: 'Android home screen glanceable optimization widget'),
          _ChangeItem(type: _ChangeType.feature, text: 'Share performance certificate as PNG image'),
          _ChangeItem(type: _ChangeType.improved, text: 'AMOLED pitch-black theme with zero battery penalty'),
          _ChangeItem(type: _ChangeType.improved, text: 'Refined non-root and Shizuku safety validation pipeline'),
        ],
      ),
      _ReleaseInfo(
        version: 'v1.5.0 - Diagnostics & Shizuku',
        date: 'August 2026',
        isLatest: false,
        changes: [
          _ChangeItem(type: _ChangeType.feature, text: 'Shizuku API integration for system-level memory trimming'),
          _ChangeItem(type: _ChangeType.feature, text: 'Network jitter and packet loss diagnostics'),
          _ChangeItem(type: _ChangeType.improved, text: 'Dynamic game package detection and category classification'),
          _ChangeItem(type: _ChangeType.security, text: 'Zero cloud telemetry: 100% on-device private processing'),
        ],
      ),
      _ReleaseInfo(
        version: 'v1.0.0 - Initial Release',
        date: 'July 2026',
        isLatest: false,
        changes: [
          _ChangeItem(type: _ChangeType.feature, text: 'Core Android device hardware identity inspector'),
          _ChangeItem(type: _ChangeType.feature, text: 'Basic safe RAM cache flushing and game launcher'),
        ],
      ),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        level: AppGlassLevel.level4,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E56DE).withOpacity(0.18),
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: const Icon(Icons.history_rounded, color: Color(0xFF5B93FF), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Release Notes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: releases.length,
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  itemBuilder: (context, index) {
                    final release = releases[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              release.version,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const Spacer(),
                            if (release.isLatest)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            Text(
                              release.date,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...release.changes.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTag(c.type),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      c.text,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(_ChangeType type) {
    Color bg;
    Color fg;
    String label;
    switch (type) {
      case _ChangeType.feature:
        bg = const Color(0xFF1E56DE).withOpacity(0.18);
        fg = const Color(0xFF5B93FF);
        label = 'NEW';
        break;
      case _ChangeType.improved:
        bg = const Color(0xFF10B981).withOpacity(0.18);
        fg = const Color(0xFF10B981);
        label = 'IMP';
        break;
      case _ChangeType.security:
        bg = const Color(0xFFF59E0B).withOpacity(0.18);
        fg = const Color(0xFFF59E0B);
        label = 'SEC';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

enum _ChangeType { feature, improved, security }

class _ChangeItem {
  final _ChangeType type;
  final String text;
  const _ChangeItem({required this.type, required this.text});
}

class _ReleaseInfo {
  final String version;
  final String date;
  final bool isLatest;
  final List<_ChangeItem> changes;

  const _ReleaseInfo({
    required this.version,
    required this.date,
    required this.isLatest,
    required this.changes,
  });
}
