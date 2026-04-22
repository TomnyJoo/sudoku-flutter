/// 锯齿数独常量定义
class JigsawConstants {
  /// 棋盘大小
  static const int boardSize = 9;
  
  /// 区域数量
  static const int regionCount = 9;
  
  /// 每个区域的单元格数量
  static const int cellsPerRegion = 9;
  
  /// 最大尝试次数（区域生成）
  static const int maxRegionGenerationAttempts = 100;
  
  /// 最大尝试次数（终盘生成）
  static const int maxSolutionGenerationAttempts = 100;
  
  /// 生成超时时间（秒）
  static const int generationTimeout = 30;
  
  /// 最小提示数
  static const int minClues = 17;
}
