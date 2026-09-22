import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/settings/moha_settings_tile.dart';
import '../providers/app_settings_provider.dart';

class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(dataManagementProvider);
    final theme = Theme.of(context);

    // Show op feedback snackbar
    ref.listen(dataManagementProvider, (prev, next) {
      if (next.status == DataOpStatus.success && next.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message!),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(dataManagementProvider.notifier).clearStatus();
      } else if (next.status == DataOpStatus.error && next.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message!),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(dataManagementProvider.notifier).clearStatus();
      }
    });

    final isLoading = dataState.status == DataOpStatus.loading;
    final stats = dataState.storageStats;

    return Scaffold(
      appBar: const MohaAppBar(
        title: 'Local Data',
        subtitle: 'Export, import, and manage stored data',
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // ── Privacy statement ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Card(
              color: theme.colorScheme.primaryContainer.withAlpha(70),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.storage_outlined,
                          color: theme.colorScheme.primary,
                          size: AppSizes.iconMd),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Stored Locally On Your Device',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No account is required. '
                      'Your profiles and history are stored on this device only — '
                      'they are never uploaded automatically.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Storage summary ─────────────────────────────────────────────────
          if (stats != null) ...[
            const SectionHeader(
              title: 'Storage Summary',
              subtitle: 'Approximate local data usage.',
              icon: Icons.bar_chart_outlined,
            ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBox(
                          label: 'Game\nProfiles',
                          value: '${stats.gameProfileCount}'),
                      _StatBox(
                          label: 'Network\nHistory',
                          value: '${stats.networkHistoryCount}'),
                      _StatBox(
                          label: 'Est. Size',
                          value: stats.estimatedStorageDisplay),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Export ──────────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Export Data',
            subtitle: 'Save your profiles and history to a local JSON file.',
            icon: Icons.upload_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: [
                  MohaSettingsTile(
                    title: 'Export All Data',
                    subtitle:
                        'Creates a backup JSON file containing your settings, '
                        'game profiles, and network history',
                    leadingIcon: Icons.download_for_offline_outlined,
                    trailing: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                    onTap: isLoading
                        ? null
                        : () => _handleExport(context, ref),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Import ──────────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Import Data',
            subtitle: 'Restore from a previously exported backup file.',
            icon: Icons.download_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: [
                  Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Only files exported from Moha Lab Optimization '
                              'are accepted. The file will be validated before '
                              'any data is changed.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.4),
                            ),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const Key('import_data_button'),
                            onPressed: isLoading
                                ? null
                                : () => _handleImport(context, ref),
                            icon: const Icon(Icons.folder_open_outlined),
                            label: const Text('Paste / Enter Import JSON'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Clear history ───────────────────────────────────────────────────
          const SectionHeader(
            title: 'Clear History',
            subtitle: 'Remove stored diagnostic records.',
            icon: Icons.history_toggle_off_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: [
                  MohaSettingsTile(
                    title: 'Clear Network Test History',
                    subtitle: 'Removes all saved network diagnostic sessions',
                    leadingIcon: Icons.network_check_outlined,
                    onTap: isLoading
                        ? null
                        : () => _confirmOp(
                              context: context,
                              title: 'Clear Network History?',
                              body:
                                  'All saved network test sessions will be permanently deleted.',
                              onConfirm: () => ref
                                  .read(dataManagementProvider.notifier)
                                  .clearNetworkHistory(),
                            ),
                    showDivider: true,
                  ),
                  MohaSettingsTile(
                    title: 'Clear All Game Profiles',
                    subtitle: 'Permanently removes all saved optimization profiles',
                    leadingIcon: Icons.gamepad_outlined,
                    onTap: isLoading
                        ? null
                        : () => _confirmOp(
                              context: context,
                              title: 'Clear All Game Profiles?',
                              body:
                                  'All your custom game profiles will be permanently deleted. '
                                  'Default profiles will regenerate automatically.',
                              onConfirm: () => ref
                                  .read(dataManagementProvider.notifier)
                                  .clearGameProfiles(),
                            ),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Danger zone ─────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Reset Application',
            subtitle: 'Factory reset — removes everything stored locally.',
            icon: Icons.warning_amber_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              color: theme.colorScheme.errorContainer.withAlpha(60),
              child: MohaSettingsTile(
                title: 'Reset All Data',
                subtitle:
                    'Wipes all settings, profiles, and history. '
                    'This cannot be undone.',
                leadingIcon: Icons.delete_forever_outlined,
                trailing: Icon(Icons.chevron_right,
                    color: theme.colorScheme.error),
                onTap: isLoading
                    ? null
                    : () => _confirmReset(context, ref),
                showDivider: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    await ref.read(dataManagementProvider.notifier).exportData();
    final state = ref.read(dataManagementProvider);
    if (!context.mounted) return;
    if (state.exportedJson != null) {
      _showExportSheet(context, state.exportedJson!);
    }
  }

  void _showExportSheet(BuildContext context, String json) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: AppRadius.radiusSm,
              ),
            ),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text('Export Data',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: json));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Copy to Clipboard'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: AppSpacing.cardPadding,
                child: SelectableText(
                  json,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Data'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste the JSON content from a Moha Lab export file below. '
                'The data will be validated before import.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('import_json_field'),
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '{ "schemaVersion": 1, ... }',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(dataManagementProvider.notifier)
          .importData(controller.text.trim());
    }
  }

  Future<void> _confirmOp({
    required BuildContext context,
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All settings\n'
          '• All game profiles\n'
          '• All diagnostic history\n\n'
          'The app will return to its initial state. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(dataManagementProvider.notifier).resetAllData();
    }
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
