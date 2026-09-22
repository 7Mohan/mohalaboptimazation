import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/shizuku_status.dart';
import '../providers/shizuku_provider.dart';

/// Full-screen bottom sheet for Shizuku onboarding, status details,
/// troubleshooting guidance, and permission management.
///
/// Opened by tapping [ShizukuStatusBanner] or from the Optimization screen.
class ShizukuSetupSheet extends ConsumerStatefulWidget {
  const ShizukuSetupSheet({super.key});

  @override
  ConsumerState<ShizukuSetupSheet> createState() => _ShizukuSetupSheetState();
}

class _ShizukuSetupSheetState extends ConsumerState<ShizukuSetupSheet> {
  bool _requestingPermission = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusAsync = ref.watch(shizukuStatusProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: cs.outlineVariant, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _SheetHeader(theme: theme, cs: cs),
                    const SizedBox(height: 20),

                    // Status card
                    statusAsync.when(
                      loading: () => const _StatusCardShimmer(),
                      error: (e, _) => _StatusCardError(cs: cs),
                      data: (status) => _StatusCard(
                        status: status,
                        theme: theme,
                        cs: cs,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    statusAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (status) => _ActionsSection(
                        status: status,
                        requesting: _requestingPermission,
                        onRefresh: _refresh,
                        onRequestPermission: _requestPermission,
                        theme: theme,
                        cs: cs,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Troubleshooting
                    statusAsync.maybeWhen(
                      data: (status) => _TroubleshootingSection(
                        status: status,
                        theme: theme,
                        cs: cs,
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Android version notes
                    _AndroidVersionNotes(theme: theme, cs: cs),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    await ref.read(shizukuStatusProvider.notifier).refresh();
  }

  Future<void> _requestPermission() async {
    setState(() => _requestingPermission = true);
    await ref.read(shizukuStatusProvider.notifier).requestPermission();
    if (mounted) setState(() => _requestingPermission = false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.theme, required this.cs});
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.security_rounded, color: cs.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shizuku',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Required for advanced system controls',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status card
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.theme,
    required this.cs,
  });
  final ShizukuStatus status;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = _colors();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.displayTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status.displayDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fg.withOpacity(0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color) _colors() => switch (status) {
        ShizukuStatus.notInstalled => (cs.errorContainer, cs.onErrorContainer, cs.error),
        ShizukuStatus.notRunning => (cs.errorContainer, cs.onErrorContainer, cs.error),
        ShizukuStatus.binderConnected => (cs.tertiaryContainer, cs.onTertiaryContainer, cs.tertiary),
        ShizukuStatus.permissionDenied => (cs.secondaryContainer, cs.onSecondaryContainer, cs.secondary),
        ShizukuStatus.permissionGranted => (cs.primaryContainer, cs.onPrimaryContainer, cs.primary),
        ShizukuStatus.ready => (cs.primaryContainer, cs.onPrimaryContainer, cs.primary),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Actions section
// ─────────────────────────────────────────────────────────────────────────────

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.status,
    required this.requesting,
    required this.onRefresh,
    required this.onRequestPermission,
    required this.theme,
    required this.cs,
  });

  final ShizukuStatus status;
  final bool requesting;
  final VoidCallback onRefresh;
  final VoidCallback onRequestPermission;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ACTIONS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (status == ShizukuStatus.binderConnected ||
            status == ShizukuStatus.permissionDenied) ...[
          FilledButton.icon(
            key: const Key('shizuku_request_permission_btn'),
            onPressed: requesting ? null : onRequestPermission,
            icon: requesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user_rounded, size: 18),
            label: Text(requesting ? 'Requesting…' : 'Request Permission'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          key: const Key('shizuku_check_status_btn'),
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Check Status'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Troubleshooting
// ─────────────────────────────────────────────────────────────────────────────

class _TroubleshootingSection extends StatelessWidget {
  const _TroubleshootingSection({
    required this.status,
    required this.theme,
    required this.cs,
  });
  final ShizukuStatus status;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final steps = _stepsForStatus();
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TROUBLESHOOTING',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: steps
                .asMap()
                .entries
                .map((e) => _TroubleshootingStep(
                      number: e.key + 1,
                      text: e.value,
                      isLast: e.key == steps.length - 1,
                      theme: theme,
                      cs: cs,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  List<String> _stepsForStatus() => switch (status) {
        ShizukuStatus.notInstalled => [
            'Install Shizuku from the Play Store or GitHub (search "Shizuku rikka").',
            'Open Shizuku after installation.',
            'Follow the in-app instructions to start the service.',
          ],
        ShizukuStatus.notRunning => [
            'Open the Shizuku app on your device.',
            'Tap "Start via Wireless Debugging" (Android 11+) or connect via ADB.',
            'For Wireless Debugging: enable Developer Options → Wireless Debugging.',
            'Once the service starts, return here and tap "Check Status".',
          ],
        ShizukuStatus.permissionDenied => [
            'Tap "Request Permission" above.',
            'In the Shizuku permission dialog, select "Allow".',
            'If the dialog does not appear, ensure Shizuku is still running.',
          ],
        ShizukuStatus.binderConnected => [
            'Tap "Request Permission" above to grant access.',
          ],
        _ => [],
      };
}

class _TroubleshootingStep extends StatelessWidget {
  const _TroubleshootingStep({
    required this.number,
    required this.text,
    required this.isLast,
    required this.theme,
    required this.cs,
  });
  final int number;
  final String text;
  final bool isLast;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: cs.outlineVariant),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Android version notes
// ─────────────────────────────────────────────────────────────────────────────

class _AndroidVersionNotes extends StatelessWidget {
  const _AndroidVersionNotes({required this.theme, required this.cs});
  final ThemeData theme;
  final ColorScheme cs;

  static const _notes = [
    ('Android 11+', 'Wireless Debugging available — no USB cable needed.'),
    ('Android 12+', 'Wireless Debugging accessible directly in Developer Options.'),
    ('MIUI / OxygenOS', 'Some OEMs kill background services. Re-start Shizuku after reboot.'),
    ('Root users', 'Shizuku can also run in root mode for persistent service.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEVICE NOTES',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ..._notes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    note.$1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.$2,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / error states
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCardShimmer extends StatelessWidget {
  const _StatusCardShimmer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _StatusCardError extends StatelessWidget {
  const _StatusCardError({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: cs.error, size: 18),
          const SizedBox(width: 10),
          Text(
            'Unable to retrieve Shizuku status.',
            style: TextStyle(color: cs.onErrorContainer),
          ),
        ],
      ),
    );
  }
}
