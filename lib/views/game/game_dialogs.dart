import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 页面级对话框/规则/确认辅助
///
/// 统一收口 GameScreen 上的交互提醒逻辑，避免页面类继续堆积大量对话框代码。
class GameDialogs {
  const GameDialogs._();

  static void showSettings(BuildContext context, String settingsRoute) {
    Navigator.pushNamed(context, settingsRoute);
  }

  static void showGameRules(BuildContext context) {
    final appLocalizations = LocalizationUtils.app(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gameLocalizations = LocalizationUtils.game(context);
    final rules = GameType.values.map((gameType) {
      try {
        final name = gameType.getLocalizedName(gameLocalizations);
        final description = gameType.getLocalizedDescription(gameLocalizations);
        return (name, description);
      } catch (_) {
        return (gameType.toString().split('.').last, '');
      }
    }).toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
        title: Text(
          appLocalizations.gameRules,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < rules.length; i++) ...[
                if (i > 0) const SizedBox(height: AppConstants.spacingStandard),
                _buildRuleSection(dialogContext, rules[i].$1, rules[i].$2),
              ],
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(appLocalizations.ok),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildRuleSection(
    BuildContext context,
    String title,
    String description,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDarkMode ? Colors.white : AppColors.darkText;
    final descriptionColor = isDarkMode
        ? Colors.white.withAlpha(200)
        : AppColors.mutedText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: titleColor,
          ),
        ),
        const SizedBox(height: AppConstants.iconTextSpacing),
        Text(
          description,
          style: TextStyle(fontSize: 13, color: descriptionColor, height: 1.4),
        ),
      ],
    );
  }

  static void confirmNewGame<T extends Board>(
    BuildContext context,
    GameViewModel<T> gameVM,
    Future<void> Function(Difficulty difficulty) newGameCallback,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.cardColor,
        title: Text(
          LocalizationUtils.app(dialogContext).newGameConfirm,
        ),
        content: Text(
          LocalizationUtils.app(dialogContext).newGameConfirmContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocalizationUtils.app(dialogContext).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final difficulty = GameUtils.getDifficultyFromIdentifier(gameVM.currentGameState.difficulty);
              if (difficulty != null) {
                await newGameCallback(difficulty);
              }
            },
            child: Text(LocalizationUtils.app(dialogContext).ok),
          ),
        ],
      ),
    );
  }

}
