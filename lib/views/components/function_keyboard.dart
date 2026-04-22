import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 功能键盘组件
class FunctionKeyboard extends StatefulWidget {
  const FunctionKeyboard({
    required this.onUndo,
    required this.onRedo,
    required this.onHint,
    required this.onMark,
    required this.onErase,
    required this.onReset,
    required this.onAutoMark,
    required this.onSolution,
    required this.onNew,
    required this.buttonSize,
    this.isMarkMode,
    this.isAutoMarkMode,
    super.key,
  });
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final ValueChanged<BuildContext> onHint;
  final VoidCallback onMark;
  final VoidCallback onErase;
  final VoidCallback onReset;
  final VoidCallback onAutoMark;
  final VoidCallback onSolution;
  final VoidCallback onNew;
  final double buttonSize;
  final bool Function()? isMarkMode;
  final bool Function()? isAutoMarkMode;

  @override
  State<FunctionKeyboard> createState() => _FunctionKeyboardState();
}

class _FunctionKeyboardState extends State<FunctionKeyboard> {
  @override
  Widget build(final BuildContext context) {
    final buttonSize = widget.buttonSize;
    const spacing = AppConstants.keyboardButtonSpacing;
    const padding = AppConstants.keyboardPadding;

    return Container(
      padding: const EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (final row) => Padding(
            padding: EdgeInsets.only(bottom: row < 2 ? spacing : 0),
            child: SizedBox(
              height: buttonSize,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (final col) {
                  final index = row * 3 + col;
                  return Padding(
                    padding: EdgeInsets.only(right: col < 2 ? spacing : 0),
                    child: _buildControlButton(
                      _getIconForIndex(index),
                      _getLabelForIndex(index),
                      _getCallbackForIndex(index),
                      index,
                      buttonSize,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndex(final int index) {
    switch (index) {
      case 0:
        return Icons.undo;
      case 1:
        return Icons.redo;
      case 2:
        return Icons.lightbulb_outline;
      case 3:
        return Icons.edit;
      case 4:
        return Icons.auto_fix_high;
      case 5:
        return Icons.clear;
      case 6:
        return Icons.visibility;
      case 7:
        return Icons.refresh;
      case 8:
        return Icons.add;
      default:
        return Icons.error;
    }
  }

  String _getLabelForIndex(final int index) {
    final localization = LocalizationUtils.app(context);
    switch (index) {
      case 0:
        return localization.undo;
      case 1:
        return localization.redo;
      case 2:
        return localization.hint;
      case 3:
        return localization.mark;
      case 4:
        return localization.autoMark;
      case 5:
        return localization.erase;
      case 6:
        return localization.solution;
      case 7:
        return localization.reset;
      case 8:
        return localization.newGame;
      default:
        return localization.error;
    }
  }

  VoidCallback _getCallbackForIndex(final int index) {
    switch (index) {
      case 0:
        return widget.onUndo;
      case 1:
        return widget.onRedo;
      case 2:
        return () => widget.onHint(context);
      case 3:
        return widget.onMark;
      case 4:
        return widget.onAutoMark;
      case 5:
        return widget.onErase;
      case 6:
        return widget.onSolution;
      case 7:
        return widget.onReset;
      case 8:
        return widget.onNew;
      default:
        return () {};
    }
  }

  Widget _buildControlButton(
    final IconData icon,
    final String label,
    final VoidCallback onPressed,
    final int index,
    final double buttonSize,
  ) {
    final isTargetButton = index == 3 || index == 4;
    final isPressed =
        isTargetButton &&
        (index == 3
            ? (widget.isMarkMode?.call() ?? false)
            : (widget.isAutoMarkMode?.call() ?? false));

    final iconSize = buttonSize * AppConstants.keyboardIconScale;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isPressed
              ? LinearGradient(
                  colors: [context.primaryColor, context.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    context.primaryColor.withAlpha(AppConstants.gradientAlpha),
                    context.secondaryColor.withAlpha(AppConstants.gradientAlpha),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(AppConstants.shadowLightAlpha),
              blurRadius: isPressed ? 6 : AppConstants.spacingSmall,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: isPressed ? Colors.white : context.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          onPressed: () {
            onPressed();
            if (isTargetButton) {
              setState(() {});
            }
          },
          child: Icon(
            icon,
            size: iconSize,
            semanticLabel: label,
            color: isPressed ? Colors.white : context.primaryColor,
          ),
        ),
      ),
    );
  }
}
