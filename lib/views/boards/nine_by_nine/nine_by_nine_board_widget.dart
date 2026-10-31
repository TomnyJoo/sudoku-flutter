import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/cell.dart';
import 'package:sudoku/renderers/board_colors.dart';
import 'package:sudoku/services/app_settings.dart';
import 'package:sudoku/views/boards/nine_by_nine/board_tap_resolver.dart';
import 'package:sudoku/views/boards/nine_by_nine/nine_by_nine_board_painter.dart';

/// 统一棋盘组件
///
/// 通过 board.gameType 条件分支处理不同游戏类型的绘制差异
class NineByNineBoardWidget extends StatelessWidget {
  const NineByNineBoardWidget({
    required this.board,
    required this.onCellSelected,
    required this.cellSize,
    this.showDiagonalLines = true,
    this.showRegionNumbers = true,
    this.showCageSums = true,
    this.showCageBorders = true,
    super.key,
  });

  final Board board;
  final Function(Cell) onCellSelected;
  final double cellSize;
  final bool showDiagonalLines;
  final bool showRegionNumbers;
  final bool showCageSums;
  final bool showCageBorders;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final boardSize = cellSize * 9;
    final colors = BoardColors.fromContext(context);

    return RepaintBoundary(
      child: GestureDetector(
        onTapUp: (final TapUpDetails details) {
          BoardTapResolver(
            board: board,
            cellSize: cellSize,
            onCellSelected: onCellSelected,
          ).handleTap(context, details);
        },
        child: SizedBox(
          width: boardSize,
          height: boardSize,
          child: CustomPaint(
            painter: NineByNineBoardPainter(
              board: board,
              cellSize: cellSize,
              colors: colors,
              highlightMistakesEnabled: settings.highlightMistakesEnabled,
              showDiagonalLines: showDiagonalLines,
              showRegionNumbers: showRegionNumbers,
              showCageSums: showCageSums,
              showCageBorders: showCageBorders,
            ),
            size: Size(boardSize, boardSize),
          ),
        ),
      ),
    );
  }
}
