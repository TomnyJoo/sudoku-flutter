import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/cell.dart';

/// 游戏逻辑服务，负责处理游戏的核心逻辑
class GameLogic {
  /// 显示完整答案
  Board showSolution(Board board, Board solution, Board initialBoard) {
    final size = solution.size;
    final newCells = <List<Cell>>[];
    
    for (int row = 0; row < size; row++) {
      final rowCells = <Cell>[];
      for (int col = 0; col < size; col++) {
        final solutionCell = solution.getCell(row, col);
        final initialCell = initialBoard.getCell(row, col);
        
        rowCells.add(Cell(
          row: row,
          col: col,
          value: solutionCell.value,
          isFixed: initialCell.isFixed,
          candidates: const {},
        ));
      }
      newCells.add(rowCells);
    }
    
    return solution.createInstance(newCells, regions: solution.regions);
  }

  /// 计算数字使用次数
  Map<int, int> calculateNumberCounts(Board board) {
    final counts = <int, int>{};
    for (var i = 1; i <= board.size; i++) {
      counts[i] = 0;
    }
    
    for (final row in board.cells) {
      for (final cell in row) {
        if (cell.value != null) {
          counts[cell.value!] = (counts[cell.value!] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

}
