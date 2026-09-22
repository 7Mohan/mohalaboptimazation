import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../providers/game_library_provider.dart';

class AddGameSheet extends ConsumerStatefulWidget {
  const AddGameSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGameSheet(),
    );
  }

  @override
  ConsumerState<AddGameSheet> createState() => _AddGameSheetState();
}

class _AddGameSheetState extends ConsumerState<AddGameSheet> {
  final _nameController = TextEditingController();
  final _packageController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, String>> _popularSuggestions = [
    {'name': 'Genshin Impact', 'package': 'com.miHoYo.GenshinImpact'},
    {'name': 'PUBG MOBILE', 'package': 'com.tencent.ig'},
    {'name': 'Call of Duty: Mobile', 'package': 'com.activision.callofduty.shooter'},
    {'name': 'Free Fire', 'package': 'com.dts.freefireth'},
    {'name': 'Roblox', 'package': 'com.roblox.client'},
    {'name': 'Minecraft', 'package': 'com.mojang.minecraftpe'},
    {'name': 'Asphalt 9: Legends', 'package': 'com.gameloft.android.ANMP.GloftA9HM'},
    {'name': 'League of Legends: Wild Rift', 'package': 'com.riotgames.league.wildrift'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _packageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final package = _packageController.text.trim();

    if (name.isEmpty || package.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Game Title and Package Name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await ref.read(gameLibraryControllerProvider.notifier).addManualGame(
          packageName: package,
          appName: name,
        );

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$name" to your Game Hub!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(
                    Icons.sports_esports_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Game to Hub',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Configure optimization profiles for any game',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Inputs
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Game Title',
                hintText: 'e.g. Call of Duty: Mobile',
                prefixIcon: const Icon(Icons.title_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextField(
              controller: _packageController,
              decoration: InputDecoration(
                labelText: 'Android Package Name',
                hintText: 'e.g. com.activision.callofduty.shooter',
                prefixIcon: const Icon(Icons.code_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Suggestions
            Text(
              'Quick Add Popular Games',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _popularSuggestions.map((game) {
                return ActionChip(
                  label: Text(game['name']!, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    _nameController.text = game['name']!;
                    _packageController.text = game['package']!;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'Adding Game...' : 'Add to Gaming Lab',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
