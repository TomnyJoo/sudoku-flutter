import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/cell.dart';
import 'package:sudoku/models/difficulty.dart';
import 'package:sudoku/models/game_stats.dart';
import 'package:sudoku/services/history_manager.dart';
import 'package:sudoku/utils/game_utils.dart';

/// Summary：游戏状态泛型类，表示整个游戏的当前状态，包括棋盘、答案、计时、历史记录等信息
/// B: 棋盘类型，必须继承自Board
class GameState<B extends Board> {
  GameState({
    required this.board,
    required this.initialBoard,
    required this.solution,
    required this.difficulty,
    this.elapsedTime = 0,
    this.mistakes = 0,
    this.isCompleted = false,
    required this.history,
    required this.stats,
    this.startTime,
    this.completionTime,
    this.isShowingSolution = false,
    this.isMarkMode = false,
    this.isAutoMarkMode = false,
    this.hintsUsed = 0,
  }) {
    // 验证参数
    if (elapsedTime < 0) {
      throw ArgumentError('已消耗时间不能为负数: $elapsedTime');
    }

    if (mistakes < 0) {
      throw ArgumentError('错误次数不能为负数: $mistakes');
    }

    if (completionTime != null &&
        startTime != null &&
        completionTime!.isBefore(startTime!)) {
      throw ArgumentError('完成时间不能早于开始时间');
    }
  }

  /// 从JSON创建游戏状态
  /// boardFromJson: 用于从JSON创建特定类型棋盘的函数
  factory GameState.fromJson(
    Map<String, dynamic> json,
    B Function(Map<String, dynamic>) boardFromJson,
  ) {
    final common = parseCommonJsonFields(json);
    final historyJson = json['history'] as List? ?? [];
    
    // 构建历史记录
    final historyStates = historyJson
        .map((b) => boardFromJson(b as Map<String, dynamic>))
        .toList();
    final history = HistoryManager(
      states: historyStates,
      currentIndex: common['historyIndex'],
    );
    
    // 构建统计服务
    final board = boardFromJson(json['board'] as Map<String, dynamic>);
    final stats = GameStats(
      board: board,
      mistakes: common['mistakes'],
      totalMoves: historyStates.length - 1,
      isCompleted: common['isCompleted'],
      elapsedTime: common['elapsedTime'],
    );
    
    return GameState<B>(
      board: board,
      initialBoard: boardFromJson(json['initialBoard'] as Map<String, dynamic>),
      solution: boardFromJson(json['solution'] as Map<String, dynamic>),
      difficulty: common['difficulty'],
      elapsedTime: common['elapsedTime'],
      mistakes: common['mistakes'],
      isCompleted: common['isCompleted'],
      history: history,
      stats: stats,
      startTime: common['startTime'],
      completionTime: common['completionTime'],
      isShowingSolution: common['isShowingSolution'],
      isMarkMode: common['isMarkMode'],
      isAutoMarkMode: common['isAutoMarkMode'],
      hintsUsed: common['hintsUsed'],
    );
  }

  final B board;  /// 当前游戏棋盘
  final B initialBoard; /// 初始谜题棋盘（用于重置游戏）
  final B solution; /// 完整答案棋盘（仅用于显示答案，不可编辑）
  final String difficulty; /// 游戏难度等级
  final int elapsedTime;  /// 已消耗时间（秒）
  final int mistakes;   /// 错误计数（违反数独规则的次数）
  final bool isCompleted; /// 是否完成游戏标志
  final HistoryManager history; /// 历史记录管理器
  final GameStats stats; /// 游戏统计服务
  final DateTime? startTime;  /// 游戏开始时间
  final DateTime? completionTime; /// 游戏完成时间
  final bool isShowingSolution; /// 是否正在显示答案
  final bool isMarkMode; /// 是否处于标记模式
  final bool isAutoMarkMode; /// 是否处于自动标记模式
  final int hintsUsed; /// 使用提示的次数

  /// 复制游戏状态，允许覆盖指定属性
  GameState<B> copyWith({
    B? board,
    B? initialBoard,
    B? solution,
    String? difficulty,
    int? elapsedTime,
    int? mistakes,
    bool? isCompleted,
    HistoryManager? history,
    GameStats? stats,
    DateTime? startTime,
    DateTime? completionTime,
    bool? isShowingSolution,
    bool? isMarkMode,
    bool? isAutoMarkMode,
    int? hintsUsed,
  }) => GameState<B>(
    board: board ?? this.board,
    initialBoard: initialBoard ?? this.initialBoard,
    solution: solution ?? this.solution,
    difficulty: difficulty ?? this.difficulty,
    elapsedTime: elapsedTime ?? this.elapsedTime,
    mistakes: mistakes ?? this.mistakes,
    isCompleted: isCompleted ?? this.isCompleted,
    history: history ?? this.history,
    stats: stats ?? this.stats,
    startTime: startTime ?? this.startTime,
    completionTime: completionTime ?? this.completionTime,
    isShowingSolution: isShowingSolution ?? this.isShowingSolution,
    isMarkMode: isMarkMode ?? this.isMarkMode,
    isAutoMarkMode: isAutoMarkMode ?? this.isAutoMarkMode,
    hintsUsed: hintsUsed ?? this.hintsUsed,
  );

  /// 创建游戏状态实例
  GameState<B> createInstance({
    required B board,
    required B initialBoard,
    required B solution,
    required String difficulty,
    int elapsedTime = 0,
    int mistakes = 0,
    bool isCompleted = false,
    required HistoryManager history,
    required GameStats stats,
    DateTime? startTime,
    DateTime? completionTime,
    bool isShowingSolution = false,
    bool isMarkMode = false,
    bool isAutoMarkMode = false,
    int hintsUsed = 0,
  }) => GameState<B>(
    board: board,
    initialBoard: initialBoard,
    solution: solution,
    difficulty: difficulty,
    elapsedTime: elapsedTime,
    mistakes: mistakes,
    isCompleted: isCompleted,
    history: history,
    stats: stats,
    startTime: startTime,
    completionTime: completionTime,
    isShowingSolution: isShowingSolution,
    isMarkMode: isMarkMode,
    isAutoMarkMode: isAutoMarkMode,
    hintsUsed: hintsUsed,
  );

  /// 获取游戏准确率
  double get accuracy => stats.accuracy;
  /// 获取游戏完成百分比
  double get completionPercentage => stats.completionPercentage;

  /// 获取选中的单元格
  /// 注意：由于 GameState 是不可变的，每次 copyWith 都创建新实例，
  /// 缓存无法跨实例保留，因此保持 O(n²) 遍历。
  /// 对于标准 9×9 棋盘（81 个单元格），性能影响可忽略不计。
  Cell? getSelectedCell() {
    for (final row in board.cells) {
      for (final cell in row) {
        if (cell.isSelected) return cell;
      }
    }
    return null;
  }

  /// 转换为JSON格式，用于持久化存储，返回包含游戏状态数据的Map
  Map<String, dynamic> toJson() => {
    'board': board.toJson(),
    'initialBoard': initialBoard.toJson(),
    'solution': solution.toJson(),
    'difficulty': difficulty,
    'elapsedTime': elapsedTime,
    'mistakes': mistakes,
    'isCompleted': isCompleted,
    'history': history.states.map((final b) => b.toJson()).toList(),
    'historyIndex': history.currentIndex,
    'startTime': startTime?.toIso8601String(),
    'completionTime': completionTime?.toIso8601String(),
    'isShowingSolution': isShowingSolution,
    'isMarkMode': isMarkMode,
    'isAutoMarkMode': isAutoMarkMode,
    'hintsUsed': hintsUsed,
  };

  /// 解析通用 JSON 字段的辅助方法
  static Map<String, dynamic> parseCommonJsonFields(Map<String, dynamic> json) {
    final historyIndex = json['historyIndex'] as int? ?? 0;
    final historyJson = json['history'] as List? ?? [];

    // 确保 historyIndex 不超过历史记录长度
    // 注意：负数在正常情况下不应该出现，如果出现说明数据已损坏
    final safeHistoryIndex = historyIndex >= historyJson.length
        ? (historyJson.isEmpty ? 0 : historyJson.length - 1)
        : historyIndex;

    return {
      'difficulty': json['difficulty'] as String? ?? 'medium',
      'elapsedTime': json['elapsedTime'] as int? ?? 0,
      'mistakes': json['mistakes'] as int? ?? 0,
      'isCompleted': json['isCompleted'] as bool? ?? false,
      'historyIndex': safeHistoryIndex,
      'startTime': json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      'completionTime': json['completionTime'] != null
          ? DateTime.parse(json['completionTime'] as String)
          : null,
      'isShowingSolution': json['isShowingSolution'] as bool? ?? false,
      'isMarkMode': json['isMarkMode'] as bool? ?? false,
      'isAutoMarkMode': json['isAutoMarkMode'] as bool? ?? false,
      'hintsUsed': json['hintsUsed'] as int? ?? 0,
    };
  }

  /// 获取用于调试的字符串表示（不依赖国际化）
  String toDebugString() {
    final timeStr = GameUtils.formatTime(elapsedTime);
    return 'GameState(difficulty: $difficulty, time: $timeStr, ' 
        'mistakes: $mistakes, completed: $isCompleted, history: ${history.length}, showingSolution: $isShowingSolution, ' 
        'isMarkMode: $isMarkMode, isAutoMarkMode: $isAutoMarkMode)';
  }

  /// 获取用于显示的字符串表示（考虑国际化）
  String toDisplayString({final dynamic localizations}) {
    final timeStr = GameUtils.formatTime(elapsedTime);

    // 使用本地化字符串或默认值
    final gameStatusText = _getLocalizedString(
      localizations,
      'gameStatus',
      '游戏状态',
    );
    final difficultyText =
        '${_getLocalizedString(localizations, 'difficulty', '难度')}: ${_getLocalizedDifficulty(localizations: localizations)}';
    final timeLabel = _getLocalizedString(localizations, 'time', '用时');
    final mistakesLabel = _getLocalizedString(localizations, 'mistakes', '错误');
    final accuracyLabel = _getLocalizedString(localizations, 'accuracy', '准确率');
    final completionLabel = _getLocalizedString(
      localizations,
      'completion',
      '完成度',
    );
    final statusLabel = _getLocalizedString(localizations, 'status', '状态');

    final accuracyPercent = (accuracy * 100).toStringAsFixed(1);
    final completionPercent = (completionPercentage * 100).toStringAsFixed(1);
    final statusValue = _getLocalizedStatus(localizations);

    return '$gameStatusText: $difficultyText, $timeLabel: $timeStr, $mistakesLabel: $mistakes, ' 
        '$accuracyLabel: $accuracyPercent%, $completionLabel: $completionPercent%, $statusLabel: $statusValue';
  }

  /// 获取本地化字符串
  String _getLocalizedString(
    dynamic localizations,
    String key,
    String defaultValue,
  ) {
    try {
      if (localizations is Map) {
        return localizations[key] ?? defaultValue;
      }
    } catch (e) {
      // 忽略异常
    }
    return defaultValue;
  }

  /// 获取本地化难度名称
  String _getLocalizedDifficulty({dynamic localizations}) {
    try {
      final difficultyEnum = Difficulty.values.firstWhere(
        (d) => d.name == difficulty,
        orElse: () => Difficulty.medium,
      );
      final config = DifficultyConfig.getConfig(difficultyEnum);
      return config.getLocalizedDifficultyName(localizations);
    } catch (e) {
      return difficulty;
    }
  }

  /// 简化的状态本地化
  String _getLocalizedStatus(dynamic localizations) {
    if (isShowingSolution) {
      return _getLocalizedString(localizations, 'showingSolution', '显示答案中');
    } else if (isCompleted) {
      return _getLocalizedString(localizations, 'completed', '已完成');
    } else {
      return _getLocalizedString(localizations, 'inProgress', '进行中');
    }
  }

  @override
  String toString() => toDebugString();
}
