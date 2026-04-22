class WindowConstants {
  static const int minFilledCells = 17;
  static const int boardSize = 9;
  static const int boxSize = 3;
  static const double functionKeyboardSpacing = 4.0;
  static const double functionKeyboardPadding = 2.0;
  static const double functionKeyboardBorderRadius = 8.0;
  static const double functionKeyboardIconScale = 0.4;
  static const double progressIndicatorWidth = 20.0;
  static const double progressIndicatorHeight = 20.0;
  static const double progressIndicatorStrokeWidth = 2.0;
  static const int maxSolutionsToCheck = 2;

  // 窗口区域定义
  // 窗口位置：左上(1-3行,1-3列)、右上(1-3行,5-7列)、左下(5-7行,1-3列)、右下(5-7行,5-7列)
  static const List<WindowRegion> windowRegions = [
    WindowRegion(
      id: 'window_top_left',
      name: 'Window Top Left',
      startRow: 1,
      startCol: 1,
      endRow: 3,
      endCol: 3,
    ),
    WindowRegion(
      id: 'window_top_right',
      name: 'Window Top Right',
      startRow: 1,
      startCol: 5,
      endRow: 3,
      endCol: 7,
    ),
    WindowRegion(
      id: 'window_bottom_left',
      name: 'Window Bottom Left',
      startRow: 5,
      startCol: 1,
      endRow: 7,
      endCol: 3,
    ),
    WindowRegion(
      id: 'window_bottom_right',
      name: 'Window Bottom Right',
      startRow: 5,
      startCol: 5,
      endRow: 7,
      endCol: 7,
    ),
  ];
}

/// 窗口区域定义类
class WindowRegion {

  const WindowRegion({
    required this.id,
    required this.name,
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });
  final String id;
  final String name;
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  /// 获取区域的宽度（列数）
  int get width => endCol - startCol + 1;

  /// 获取区域的高度（行数）
  int get height => endRow - startRow + 1;
}
