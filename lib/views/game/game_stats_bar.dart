import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/index.dart';

class GameStatsBar<B extends Board> extends StatelessWidget {
  const GameStatsBar({
    super.key,
    required this.viewModel,
    required this.isSamuraiGame,
    required this.isDarkMode,
  });

  final GameViewModel<B> viewModel;
  final bool isSamuraiGame;
  final bool isDarkMode;

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    Color color,
  ) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingSmall),
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: AppConstants.statsIconSize, color: color),
        ),
        const SizedBox(width: AppConstants.iconTextSpacing),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveLayout.getResponsiveFontSize(14, context),
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsiveBorderRadius = ResponsiveLayout.getResponsiveBorderRadius(context);

    final statItems = <Widget>[
      Selector<GameViewModel<B>, int>(
        selector: (_, vm) => vm.currentGameState.elapsedTime,
        builder: (_, elapsedTime, _) => _buildStatItem(
          context,
          Icons.timer,
          GameUtils.formatTime(elapsedTime),
          context.infoColor,
        ),
      ),
      Selector<GameViewModel<B>, int>(
        selector: (_, vm) => vm.errorCount,
        builder: (_, errorCount, _) => _buildStatItem(
          context,
          Icons.warning_amber,
          errorCount.toString(),
          context.errorColor,
        ),
      ),
      _buildStatItem(
        context,
        Icons.star_half,
        viewModel.getLocalizedDifficulty(context),
        context.warningColor,
      ),
      Selector<GameViewModel<B>, (int, String?)>(
        selector: (_, vm) => (vm.currentGameState.elapsedTime, vm.bestScoreDisplayTime),
        builder: (_, data, _) => _buildStatItem(
          context,
          Icons.emoji_events,
          data.$2 ?? GameUtils.formatTime(data.$1),
          Colors.amber,
        ),
      ),
    ];

    if (isSamuraiGame) {
      statItems.add(
        Selector<GameViewModel<B>, bool>(
          selector: (_, vm) => vm.isOverviewMode,
          builder: (_, isOverviewMode, _) {
            if (!isOverviewMode) return const SizedBox.shrink();
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      LocalizationUtils.app(context).tapSubGridToEdit,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.getResponsivePadding(context) * 0.8,
        vertical: AppConstants.spacingMedium,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingMedium,
        horizontal: AppConstants.spacingStandard,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  context.primaryColor.withAlpha(51),
                  context.primaryColor.withAlpha(26),
                ]
              : [Colors.white.withAlpha(38), Colors.white.withAlpha(13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
        border: Border.all(
          color: isDarkMode
              ? context.borderColor.withAlpha(102)
              : Colors.white.withAlpha(51),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: statItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Row(
              children: [
                item,
                if (index < statItems.length - 1)
                  const SizedBox(width: AppConstants.spacingLarge),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
