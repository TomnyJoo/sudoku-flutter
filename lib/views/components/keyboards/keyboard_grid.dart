import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 通用 3×3 键盘网格布局
///
/// 为 [NumberKeyboard] 和 [FunctionKeyboard] 提供统一的网格容器，
/// 按钮内容由 [buttonBuilder] 按索引（0~8）构建。
class KeyboardGrid extends StatelessWidget {
  const KeyboardGrid({
    required this.buttonSize,
    required this.buttonBuilder,
    super.key,
  });

  final double buttonSize;
  final Widget Function(int index) buttonBuilder;

  @override
  Widget build(BuildContext context) {
    const spacing = AppConstants.keyboardButtonSpacing;
    const padding = AppConstants.keyboardPadding;

    return Container(
      padding: const EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (row) => Padding(
            padding: EdgeInsets.only(bottom: row < 2 ? spacing : 0),
            child: SizedBox(
              height: buttonSize,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (col) {
                  final index = row * 3 + col;
                  return Padding(
                    padding: EdgeInsets.only(right: col < 2 ? spacing : 0),
                    child: buttonBuilder(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
