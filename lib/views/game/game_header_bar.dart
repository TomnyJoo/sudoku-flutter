import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

class GameHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const GameHeaderBar({
    super.key,
    required this.title,
    required this.onBackPressed,
    required this.onHelpPressed,
    required this.onSettingsPressed,
    this.actions,
    required this.isDarkMode,
    this.isHorizontalLayout = false,
  });

  final String title;
  final List<Widget>? actions;
  final VoidCallback onBackPressed;
  final VoidCallback onHelpPressed;
  final VoidCallback onSettingsPressed;
  final bool isDarkMode;
  final bool isHorizontalLayout;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildTitleText(BuildContext context, {required bool isPortrait}) => Text(
        title,
        style: TextStyle(
          fontSize: isPortrait ? 16 : 18,
          fontWeight: FontWeight.bold,
          color: isPortrait ? null : (isDarkMode ? Colors.white : Colors.black87),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final iconColor = isDarkMode ? Colors.white.withAlpha(200) : AppColors.mutedText;

    if (isHorizontalLayout) {
      return Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
        decoration: BoxDecoration(
          color: context.cardColor.withAlpha(180),
          border: Border(
            bottom: BorderSide(color: Colors.grey.withAlpha(51)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: onBackPressed,
            ),
            const SizedBox(width: AppConstants.spacingStandard),
            _buildTitleText(context, isPortrait: false),
            const Spacer(),
            ...?actions,
            IconButton(
              icon: Icon(
                Icons.help_outline,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: onHelpPressed,
            ),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: onSettingsPressed,
            ),
          ],
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? AppColors.homeBackgroundGradientDark
                : AppColors.homeBackgroundGradientLight,
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: onBackPressed,
      ),
      title: _buildTitleText(context, isPortrait: true),
      foregroundColor: iconColor,
      actions: [
        ...?actions,
        IconButton(
          icon: Icon(Icons.help_outline, color: iconColor),
          onPressed: onHelpPressed,
        ),
        IconButton(
          icon: Icon(Icons.settings, color: iconColor),
          onPressed: onSettingsPressed,
        ),
      ],
    );
  }
}
