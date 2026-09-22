import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/ads/ad_placement.dart';
import '../../../../shared/widgets/ads/moha_banner_ad_widget.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/dialogs/moha_bottom_sheet.dart';
import '../../../../shared/widgets/feedback/moha_empty_state.dart';
import '../../../../shared/widgets/feedback/moha_error_state.dart';
import '../../../../shared/widgets/feedback/moha_loading_state.dart';
import '../../../../shared/widgets/glass/animated_entry.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../domain/entities/game_entity.dart';
import '../providers/game_library_provider.dart';
import '../widgets/add_game_sheet.dart';
import '../widgets/game_card_item.dart';
import '../widgets/game_detail_sheet.dart';

/// Screen displaying detected games on the user's Android device.
class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(gameSearchQueryProvider.notifier).state = value;
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(gameSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gamesAsync = ref.watch(filteredGamesProvider);
    final allGamesAsync = ref.watch(gameLibraryControllerProvider);
    final totalGamesCount = allGamesAsync.asData?.value.length ?? 0;
    final currentSort = ref.watch(gameSortOrderProvider);

    return Scaffold(
      appBar: MohaAppBar(
        title: 'Games',
        subtitle: totalGamesCount > 0
            ? '$totalGamesCount detected on device'
            : 'Installed gaming applications',
        actions: [
          IconButton(
            tooltip: _isSearchExpanded ? 'Close Search' : 'Search Games',
            icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearchExpanded) {
                  _clearSearch();
                  _isSearchExpanded = false;
                } else {
                  _isSearchExpanded = true;
                }
              });
            },
          ),
          IconButton(
            tooltip: 'Discovery Info',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showDetectionInfo(context),
          ),
          IconButton(
            tooltip: 'Rescan Device',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(gameLibraryControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(gameLibraryControllerProvider.notifier).refresh(),
        child: Column(
          children: [
            // Search Input Header (visible when expanded)
            if (_isSearchExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Filter by title or package name...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: _clearSearch,
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMd,
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ),

            // Controls bar (only shown if games exist)
            if (totalGamesCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DETECTED GAMES ($totalGamesCount)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    PopupMenuButton<GameSortOrder>(
                      tooltip: 'Sort Options',
                      initialValue: currentSort,
                      onSelected: (order) {
                        ref.read(gameSortOrderProvider.notifier).state = order;
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentSort.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      itemBuilder: (context) => [
                        for (final order in GameSortOrder.values)
                          PopupMenuItem(
                            value: order,
                            child: Text(order.label),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            // Main Content Area
            Expanded(
              child: gamesAsync.when(
                loading: () => ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, _) => Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: AppRadius.radiusLg,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        MohaSkeleton(
                          width: 44,
                          height: 44,
                          borderRadius: AppRadius.radiusMd,
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MohaSkeleton(width: 130, height: 16),
                              SizedBox(height: 6),
                              MohaSkeleton(width: 190, height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (err, _) => MohaErrorState(
                  title: 'Game Detection Failed',
                  message: 'Unable to scan installed packages. Check app permissions and retry.',
                  onRetry: () => ref.read(gameLibraryControllerProvider.notifier).refresh(),
                ),
                data: (games) {
                  // If there are truly no games installed on the device
                  if (totalGamesCount == 0) {
                    return ListView(
                      children: [
                        MohaEmptyState(
                          icon: Icons.sports_esports_outlined,
                          title: 'No games detected yet',
                          description:
                              'Moha Lab automatically scans installed packages with the Android GAME category tag.\n'
                              'Install games from Google Play or tap Rescan to refresh.',
                          actionLabel: 'How Detection Works',
                          onAction: () => _showDetectionInfo(context),
                        ),
                      ],
                    );
                  }

                  // If search filtered out all results
                  if (games.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No matching games found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'No installed games match "${_searchController.text}".',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextButton(
                              onPressed: _clearSearch,
                              child: const Text('Clear Search Filter'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Render detected games list
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: games.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return AnimatedEntry.staggered(
                        index: index,
                        child: GestureDetector(
                          onLongPress: () => _confirmRemoveGame(context, game),
                          child: GameCardItem(
                            game: game,
                            onTap: () {
                              GameDetailSheet.show(
                                context: context,
                                game: game,
                                onLaunch: () => _launchGame(game),
                              );
                            },
                            onLaunch: () => _launchGame(game),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Banner ad — anchored below the game list, never covering list items.
            // Collapses to SizedBox.shrink() when ad is not loaded.
            const MohaBannerAdWidget(placement: AdPlacement.gameDetailBanner),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddGameSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Game'),
      ),
    );
  }

  void _confirmRemoveGame(BuildContext context, GameEntity game) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove "${game.appName}"?'),
        content: const Text(
            'This game will be removed from your active Gaming Lab list. You can add it back anytime or rescan your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(gameLibraryControllerProvider.notifier)
                  .removeGame(game.packageName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed ${game.appName} from Gaming Hub'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _launchGame(GameEntity game) async {
    final launched = await ref
        .read(gameLibraryControllerProvider.notifier)
        .launchGame(game.packageName);

    if (!mounted) return;

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to launch ${game.appName}. Activity not found.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDetectionInfo(BuildContext context) {
    MohaBottomSheet.show(
      context: context,
      title: 'Game Discovery Engine',
      subtitle: 'On-device, privacy-first cataloging',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoPoint(
            icon: Icons.search_rounded,
            title: 'Android Package Manager',
            description:
                'Moha Lab inspects app manifests for the official CATEGORY_GAME attribute declared by game developers.',
            statusType: MohaStatusType.safe,
          ),
          SizedBox(height: AppSpacing.md),
          _InfoPoint(
            icon: Icons.lock_outline_rounded,
            title: 'Strictly Offline & Private',
            description:
                'Your installed applications are never sent to external servers, Firebase, or third-party analytics.',
            statusType: MohaStatusType.safe,
          ),
          SizedBox(height: AppSpacing.md),
          _InfoPoint(
            icon: Icons.tune_rounded,
            title: 'Multi-Signal Classification',
            description:
                'Evaluates CATEGORY_GAME, FLAG_IS_GAME, GAME launcher intents, and game engine metadata.',
            statusType: MohaStatusType.optimal,
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _InfoPoint extends StatelessWidget {
  const _InfoPoint({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusType,
  });

  final IconData icon;
  final String title;
  final String description;
  final MohaStatusType statusType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: AppSizes.iconSm, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  MohaStatusBadge(type: statusType),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
