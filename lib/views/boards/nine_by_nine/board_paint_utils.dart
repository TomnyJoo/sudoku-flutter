import 'package:flutter/material.dart';
import 'package:sudoku/models/cell.dart';

class JigsawRegionCache {
  const JigsawRegionCache({
    required this.cellsByRegion,
    required this.minCellByRegion,
  });

  final Map<int, List<(int, int)>> cellsByRegion;
  final Map<int, (int, int)> minCellByRegion;
}

/// 统一棋盘绘制辅助逻辑
///
/// 把纯计算型逻辑从 painter 中抽离，降低渲染类的复杂度。
class BoardPaintUtils {
  const BoardPaintUtils._();

  static JigsawRegionCache buildRegionCache(List<List<int>> matrix) {
    final cellsByRegion = <int, List<(int, int)>>{};
    final minCellByRegion = <int, (int, int)>{};

    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        final regionId = matrix[row][col];
        final cell = (row, col);
        cellsByRegion.putIfAbsent(regionId, () => []).add(cell);
        if (regionId >= 0 && regionId < 9) {
          minCellByRegion.putIfAbsent(regionId, () => cell);
        }
      }
    }

    return JigsawRegionCache(
      cellsByRegion: cellsByRegion,
      minCellByRegion: minCellByRegion,
    );
  }

  static void drawTextInCenter(Canvas canvas, String text, Rect rect, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final offset = Offset(
      rect.center.dx - textPainter.width / 2,
      rect.center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  static bool areCellsEqual(Cell a, Cell b) =>
      a.value == b.value &&
      a.isFixed == b.isFixed &&
      a.isSelected == b.isSelected &&
      a.isHighlighted == b.isHighlighted &&
      a.isError == b.isError &&
      a.candidates.length == b.candidates.length &&
      areSetsEqual(a.candidates, b.candidates);

  static bool areSetsEqual(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }
}
