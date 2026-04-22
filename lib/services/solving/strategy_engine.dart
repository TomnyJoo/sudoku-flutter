import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/candidate_calculator.dart';
import 'package:sudoku/services/solving/strategies/killer_strategies.dart';
import 'package:sudoku/services/solving/strategies/solving_strategies.dart';

/// 策略抽象基类
/// 所有求解策略必须继承此类并实现 apply 方法
abstract class Strategy {
  const Strategy();

  /// 策略类型
  StrategyType get type;

  /// 策略级别
  StrategyLevel get level;

  /// 适用的游戏类型
  Set<GameType> get applicableGames;

  /// 应用策略到棋盘上下文
  /// 返回 true 表示有候选数被修改
  bool apply(BoardContext context);
}

/// 策略注册表
class StrategyRegistry {
  static final Map<StrategyType, Strategy> _strategies = {};

  static void register(Strategy strategy) {
    _strategies[strategy.type] = strategy;
  }

  static Strategy? get(StrategyType type) => _strategies[type];

  /// 获取所有已注册的策略
  static List<Strategy> getAllStrategies() => _strategies.values.toList();

  static List<Strategy> getForGame(GameType gameType) => _strategies.values
      .where((s) => s.applicableGames.contains(gameType))
      .toList()
      ..sort((a, b) => a.level.index.compareTo(b.level.index));

  static List<Strategy> getForLevel(StrategyLevel maxLevel) =>
      _strategies.values
          .where((s) => s.level.index <= maxLevel.index)
          .toList()
          ..sort((a, b) => a.level.index.compareTo(b.level.index));

  static List<Strategy> getForGameAndLevel(
    GameType gameType,
    StrategyLevel maxLevel,
  ) => _strategies.values
      .where(
        (s) =>
            s.applicableGames.contains(gameType) &&
            s.level.index <= maxLevel.index,
      )
      .toList()
      ..sort((a, b) => a.level.index.compareTo(b.level.index));
}

/// 策略服务 - 负责初始化和执行策略
class StrategyService {
  StrategyService._();
  static StrategyService? _instance;

  static StrategyService get instance {
    _instance ??= StrategyService._();
    return _instance!;
  }

  bool _isInitialized = false;

  /// 初始化策略服务，注册所有策略
  static void initialize() {
    if (instance._isInitialized) return;
    instance.._registerAllStrategies()
    .._isInitialized = true;
  }

  void _registerAllStrategies() {
    // 基础策略
    StrategyRegistry.register(const NakedSingleStrategy());
    StrategyRegistry.register(const HiddenSingleStrategy());
    // 中级策略
    StrategyRegistry.register(const NakedPairStrategy());
    StrategyRegistry.register(const HiddenPairStrategy());
    StrategyRegistry.register(const LockedCandidateStrategy());
    // 高级策略
    StrategyRegistry.register(const NakedTripleStrategy());
    StrategyRegistry.register(const HiddenTripleStrategy());
    StrategyRegistry.register(const XWingStrategy());
    StrategyRegistry.register(const SwordfishStrategy());
    // 杀手数独策略
    StrategyRegistry.register(const KillerCageConstraintStrategy());
    StrategyRegistry.register(const Killer45RuleStrategy());
    StrategyRegistry.register(const KillerOverlapEliminationStrategy());
    StrategyRegistry.register(const KillerCageBlockingStrategy());
  }

  /// 应用所有策略到棋盘上下文
  void applyStrategies(BoardContext context) {
    final strategies = StrategyRegistry.getAllStrategies();
    for (final strategy in strategies) {
      strategy.apply(context);
    }
  }

  /// 应用指定游戏类型的策略
  void applyStrategiesForGame(BoardContext context, GameType gameType) {
    final strategies = StrategyRegistry.getForGame(gameType);
    for (final strategy in strategies) {
      strategy.apply(context);
    }
  }
}
