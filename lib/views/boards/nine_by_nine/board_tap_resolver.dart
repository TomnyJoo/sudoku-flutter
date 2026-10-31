import 'package:flutter/material.dart';
import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/cell.dart';

/// 统一棋盘交互解析器
///
/// 将点击定位、位置换算与单元格选择逻辑从展示组件中拆出，
/// 让组件只负责组合与回调绑定。
class BoardTapResolver {
  const BoardTapResolver({
    required this.board,
    required this.cellSize,
    required this.onCellSelected,
  });

  final Board board;
  final double cellSize;
  final void Function(Cell) onCellSelected;

  void handleTap(BuildContext context, TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = box.globalToLocal(details.globalPosition);
    final col = (localPosition.dx / cellSize).floor();
    final row = (localPosition.dy / cellSize).floor();

    if (row >= 0 && row < 9 && col >= 0 && col < 9) {
      onCellSelected(board.cells[row][col]);
    }
  }
}
