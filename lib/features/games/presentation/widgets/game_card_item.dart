import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../shared/widgets/cards/moha_game_card.dart';
import '../../domain/entities/game_entity.dart';

/// Presentation card displaying a detected game with icon and status.
class GameCardItem extends StatelessWidget {
  const GameCardItem({
    super.key,
    required this.game,
    required this.onTap,
    required this.onLaunch,
  });

  final GameEntity game;
  final VoidCallback onTap;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? iconWidget;
    if (game.iconBytes != null) {
      iconWidget = ClipRRect(
        borderRadius: AppRadius.radiusMd,
        child: Image.memory(
          game.iconBytes!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.sports_esports,
            color: theme.colorScheme.primary,
            size: AppSizes.iconLg,
          ),
        ),
      );
    }

    return MohaGameCard(
      title: game.appName,
      packageName: '${game.packageName} • ${game.versionDisplay}',
      statusType: game.statusType,
      statusLabel: game.statusLabel,
      icon: iconWidget,
      onTap: onTap,
      onLaunch: onLaunch,
    );
  }
}
