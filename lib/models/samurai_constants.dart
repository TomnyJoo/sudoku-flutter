class SamuraiConstants {
  static const int boardSize = 21;
  static const int subGridSize = 9;
  static const int subGridCount = 5;
  
  // 子数独的起始位置
  static const List<(int, int)> subGridOffsets = [
    (0, 0),      // 左上
    (0, 12),     // 右上
    (12, 0),     // 左下
    (12, 12),    // 右下
    (6, 6),      // 中心
  ];
  
  // 子数独名称（使用 key 标识符，实际显示通过国际化处理）
  static const List<String> subGridNames = [
    'topLeft',
    'topRight',
    'bottomLeft',
    'bottomRight',
    'center',
  ];
  
  // 重叠区域的位置
  static const List<(int, int, int, int)> overlapRegions = [
    (6, 6, 8, 8),    // 左上与中心重叠
    (6, 14, 8, 16),   // 右上与中心重叠
    (14, 6, 16, 8),   // 左下与中心重叠
    (14, 14, 16, 16), // 右下与中心重叠
  ];
  
  // 难度级别对应的提示数
  static const Map<String, int> difficultyClues = {
    'beginner': 45,
    'easy': 40,
    'medium': 35,
    'hard': 30,
    'expert': 25,
    'master': 17,
  };
}
