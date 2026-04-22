import 'dart:math';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/candidate_calculator.dart';
import 'package:sudoku/services/solving/strategy_engine.dart';

/// 杀手数独组合检查器
/// 提供笼子约束验证和组合枚举功能
class KillerCombinationChecker {
  /// 应用笼子约束到候选数
  static void applyCageConstraint(
    int sum,
    List<(int, int)> cellCoordinates,
    Set<int> Function(int, int) getCandidates,
    void Function(int, int, Set<int>) setCandidates,
    int? Function(int, int) getCellValue,
  ) {
    final filled = <int>{};
    int filledSum = 0;
    final emptyIndices = <int>[];
    final emptyCandidates = <Set<int>>[];

    for (int i = 0; i < cellCoordinates.length; i++) {
      final (r, c) = cellCoordinates[i];
      final val = getCellValue(r, c);
      if (val != null) {
        filled.add(val);
        filledSum += val;
      } else {
        emptyIndices.add(i);
        emptyCandidates.add(getCandidates(r, c));
      }
    }

    final remainingSum = sum - filledSum;
    if (remainingSum <= 0 || emptyIndices.isEmpty) return;

    // 计算所有合法组合
    final validDigits = <Set<int>>[];
    _findCombinations(
      0,
      emptyIndices.length,
      remainingSum,
      filled,
      <int>[],
      validDigits,
      emptyCandidates: emptyCandidates,
    );

    if (validDigits.isEmpty) return;

    // 计算每个位置的可能数字
    for (int i = 0; i < emptyIndices.length; i++) {
      final (r, c) = cellCoordinates[emptyIndices[i]];
      final possible = <int>{};
      for (final combo in validDigits) {
        possible.add(combo.elementAt(i));
      }
      final current = getCandidates(r, c);
      final newCandidates = current.intersection(possible);
      setCandidates(r, c, newCandidates);
    }
  }

  /// 检查是否存在包含指定数字的组合
  static bool existsCombination(
    int k,
    int targetSum,
    Set<int> used,
    List<Set<int>> emptyCandidates,
    int forceDigit,
  ) {
    bool found = false;
    _findCombinations(
      0,
      k,
      targetSum,
      used,
      <int>[],
      [],
      emptyCandidates: emptyCandidates,
      forceDigit: forceDigit,
      onFound: (_) => found = true,
      earlyStop: true,
    );
    return found;
  }

  static void _findCombinations(
    int index,
    int k,
    int targetSum,
    Set<int> used,
    List<int> current,
    List<Set<int>> result, {
    List<Set<int>> emptyCandidates = const [],
    int? forceDigit,
    void Function(List<int>)? onFound,
    bool earlyStop = false,
  }) {
    if (index == k) {
      if (targetSum == 0) {
        if (forceDigit != null && !current.contains(forceDigit)) return;
        if (onFound != null) {
          onFound(current);
        } else {
          result.add(current.toSet());
        }
      }
      return;
    }

    for (int num = 1; num <= 9; num++) {
      if (used.contains(num)) continue;
      if (num > targetSum) break;

      // 检查候选数约束
      if (index < emptyCandidates.length) {
        if (!emptyCandidates[index].contains(num)) continue;
      }

      current.add(num);
      final newUsed = Set<int>.from(used)..add(num);

      _findCombinations(
        index + 1,
        k,
        targetSum - num,
        newUsed,
        current,
        result,
        forceDigit: forceDigit,
        onFound: onFound,
        earlyStop: earlyStop,
      );

      current.removeLast();

      if (earlyStop && result.isNotEmpty) return;
    }
  }
}

/// 杀手数独笼子约束策略
class KillerCageConstraintStrategy extends Strategy {
  const KillerCageConstraintStrategy();

  @override
  StrategyType get type => StrategyType.killerCageConstraint;

  @override
  StrategyLevel get level => StrategyLevel.basic;

  @override
  Set<GameType> get applicableGames => {GameType.killer};

  @override
  bool apply(BoardContext context) {
    final cages = context.killerCages;
    if (cages == null) return false;

    bool changed = false;
    for (final cage in cages) {
      final oldCandidates = _captureCandidates(context, cage);
      _applyCageConstraint(context, cage);
      if (_candidatesChanged(context, cage, oldCandidates)) {
        changed = true;
      }
    }
    return changed;
  }

  Set<int> _captureCandidates(BoardContext context, KillerCage cage) {
    final result = <int>{};
    for (final (r, c) in cage.cellCoordinates) {
      result.addAll(context.getCandidates(r, c));
    }
    return result;
  }

  bool _candidatesChanged(BoardContext context, KillerCage cage, Set<int> oldCandidates) {
    final current = <int>{};
    for (final (r, c) in cage.cellCoordinates) {
      current.addAll(context.getCandidates(r, c));
    }
    return !setEquals(oldCandidates, current);
  }

  static bool setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  void _applyCageConstraint(BoardContext context, KillerCage cage) {
    KillerCombinationChecker.applyCageConstraint(
      cage.sum,
      cage.cellCoordinates,
      (r, c) => context.getCandidates(r, c),
      (r, c, candidates) => context.setCandidates(r, c, candidates),
      (r, c) => context.board.getCell(r, c).value,
    );
  }
}

/// 杀手数独45法则策略
class Killer45RuleStrategy extends Strategy {
  const Killer45RuleStrategy();

  @override
  StrategyType get type => StrategyType.killer45Rule;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => {GameType.killer};

  @override
  bool apply(BoardContext context) {
    bool changed = false;
    for (int i = 0; i < context.size; i++) {
      if (_apply45RuleToLine(context, i, true)) changed = true;
      if (_apply45RuleToLine(context, i, false)) changed = true;
      if (_apply45RuleToBlock(context, i)) changed = true;
    }
    return changed;
  }

  bool _apply45RuleToLine(BoardContext context, int index, bool isRow) {
    final cells = <(int, int)>[];
    for (int i = 0; i < context.size; i++) {
      cells.add(isRow ? (index, i) : (i, index));
    }
    return _apply45RuleToCells(context, cells);
  }

  bool _apply45RuleToBlock(BoardContext context, int blockIndex) {
    // 动态获取宫大小
    final maxNumber = context.board.getMaxNumber();
    final blockSize = sqrt(maxNumber).toInt();
    final boxRow = (blockIndex ~/ blockSize) * blockSize;
    final boxCol = (blockIndex % blockSize) * blockSize;
    final cells = <(int, int)>[];
    for (int r = boxRow; r < boxRow + blockSize; r++) {
      for (int c = boxCol; c < boxCol + blockSize; c++) {
        cells.add((r, c));
      }
    }
    return _apply45RuleToCells(context, cells);
  }

  /// 通用方法：应用组合约束到单元格
  bool _applyCombinationConstraintToCells(
    BoardContext context,
    List<(int, int)> cells,
    int targetSum,
  ) {
    bool changed = false;
    final unfilled = <(int, int)>[];
    int filledSum = 0;
    
    for (final (r, c) in cells) {
      final val = context.board.getCell(r, c).value;
      if (val != null) {
        filledSum += val;
      } else {
        unfilled.add((r, c));
      }
    }
    
    final remainingSum = targetSum - filledSum;
    
    if (unfilled.isEmpty) return false;
    
    if (remainingSum < 0 || remainingSum == 0) {
      // 矛盾：和为负数或零，但有未填单元格，清空所有未填单元格的候选数
      for (final (r, c) in unfilled) {
        context.setCandidates(r, c, <int>{});
        changed = true;
      }
      return changed;
    }
    
    if (unfilled.length == 1) {
      final (r, c) = unfilled.first;
      final oldSet = context.getCandidates(r, c).toSet();
      final maxNumber = context.board.getMaxNumber();
      if (remainingSum >= 1 && remainingSum <= maxNumber) {
        final newSet = oldSet.intersection({remainingSum});
        if (newSet.isNotEmpty && newSet.length != oldSet.length) {
          context.setCandidates(r, c, newSet);
          changed = true;
        }
      }
    } else {
      const maxLargeCageSize = 5;
      if (unfilled.length <= maxLargeCageSize) {
        // 使用现有的KillerCombinationChecker.applyCageConstraint方法
        // 创建临时的getCandidates和setCandidates函数
        Set<int> tempGetCandidates(int r, int c) => context.getCandidates(r, c);

        void tempSetCandidates(int r, int c, Set<int> candidates) {
          final oldSet = context.getCandidates(r, c).toSet();
          if (candidates != oldSet && candidates.isNotEmpty) {
            context.setCandidates(r, c, candidates);
            changed = true;
          }
        }

        int? tempGetCellValue(int r, int c) => context.board.getCell(r, c).value;

        // 应用约束
        KillerCombinationChecker.applyCageConstraint(
          remainingSum,
          unfilled,
          tempGetCandidates,
          tempSetCandidates,
          tempGetCellValue,
        );
      }
    }
    
    return changed;
  }

  bool _apply45RuleToCells(BoardContext context, List<(int, int)> cells) {
    bool changed = false;
    int filledSum = 0;
    final unfilledCells = <(int, int)>[];
    for (final (r, c) in cells) {
      final val = context.board.getCell(r, c).value;
      if (val != null) {
        filledSum += val;
      } else {
        unfilledCells.add((r, c));
      }
    }

    // 动态计算区域的目标和
    final maxNumber = context.board.getMaxNumber();
    final targetSum = maxNumber * (maxNumber + 1) ~/ 2;
    final remainingSum = targetSum - filledSum;
    if (remainingSum < 0) return false;
    if (unfilledCells.isEmpty) return false;

    final cagesInRegion = <KillerCage>[];
    for (final cage in context.killerCages ?? []) {
      int insideCount = 0;
      for (final (r, c) in cage.cellCoordinates) {
        if (cells.contains((r, c))) {
          insideCount++;
        }
      }
      if (insideCount == cage.cellCoordinates.length) {
        cagesInRegion.add(cage);
      }
    }

    int cagesSum = 0;
    for (final cage in cagesInRegion) {
      int cageFilledSum = 0;
      for (final (r, c) in cage.cellCoordinates) {
        final val = context.board.getCell(r, c).value;
        if (val != null) cageFilledSum += val;
      }
      cagesSum += cage.sum - cageFilledSum;
    }

    final remainingOutside = remainingSum - cagesSum;
    if (remainingOutside < 0) return false;

    final freeCells = <(int, int)>[];
    if (cagesInRegion.isEmpty) {
      // 当没有完整笼子时，所有空单元格都是自由单元格
      freeCells.addAll(unfilledCells);
    } else {
      // 当有完整笼子时，只处理不在完整笼子内的空单元格
      for (final (r, c) in unfilledCells) {
        final cage = context.getCageForCell(r, c);
        if (cage == null || !cagesInRegion.contains(cage)) {
          freeCells.add((r, c));
        }
      }
    }

    if (freeCells.isNotEmpty) {
      // 处理 remainingOutside == 0 的情况
      if (remainingOutside == 0) {
        // 剩余和为0但有自由单元格，这是一个矛盾
        // 清空所有自由单元格的候选数
        for (final (r, c) in freeCells) {
          context.setCandidates(r, c, <int>{});
          changed = true;
        }
      } else {
        changed = _applyCombinationConstraintToCells(context, freeCells, remainingOutside) || changed;
      }
    }
    return changed;
  }
}

/// 杀手数独交叉排除策略
class KillerOverlapEliminationStrategy extends Strategy {
  const KillerOverlapEliminationStrategy();

  @override
  StrategyType get type => StrategyType.killerOverlapElimination;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => {GameType.killer};

  @override
  bool apply(BoardContext context) {
    bool changed = false;
    final Map<int, Set<int>> adjacency = {};
    final cages = context.killerCages ?? [];
    for (int i = 0; i < cages.length; i++) {
      adjacency[i] = {};
      for (int j = i + 1; j < cages.length; j++) {
        if (_cagesOverlap(cages[i], cages[j])) {
          adjacency[i]!.add(j);
          adjacency[j]!.add(i);
        }
      }
    }

    final visited = <int>{};
    for (int i = 0; i < cages.length; i++) {
      if (visited.contains(i)) continue;
      final component = <int>[];
      final queue = [i];
      while (queue.isNotEmpty) {
        final cur = queue.removeAt(0);
        if (visited.contains(cur)) continue;
        visited.add(cur);
        component.add(cur);
        for (final neighbor in adjacency[cur]!) {
          if (!visited.contains(neighbor)) {
            queue.add(neighbor);
          }
        }
      }
      if (component.length > 1) {
        if (_applyCrossEliminationForCageGroup(context, component, cages)) {
          changed = true;
        }
      }
    }
    return changed;
  }

  bool _cagesOverlap(KillerCage a, KillerCage b) {
    for (final cellA in a.cellCoordinates) {
      for (final cellB in b.cellCoordinates) {
        if (cellA == cellB) return true;
      }
    }
    return false;
  }

  bool _applyCrossEliminationForCageGroup(
    BoardContext context,
    List<int> cageIndices,
    List<KillerCage> cages,
  ) {
    bool changed = false;
    final cageGroup = cageIndices.map((i) => cages[i]).toList();
    
    // 预计算每个笼子的可能数字集合
    final Map<KillerCage, Set<int>> cagePossibleDigits = {};
    for (final cage in cageGroup) {
      cagePossibleDigits[cage] = _getPossibleDigitsForCage(context, cage);
    }
    
    final allCells = <(int, int)>{};
    for (final cage in cageGroup) {
      allCells.addAll(cage.cellCoordinates);
    }
    final cellList = allCells.toList();
    
    for (final (r, c) in cellList) {
      final relevantCages = cageGroup
          .where((cage) => cage.cellCoordinates.contains((r, c)))
          .toList();
      if (relevantCages.length < 2) continue;

      final oldSet = context.getCandidates(r, c).toSet();
      if (oldSet.isEmpty) continue;
      
      // 计算所有相关笼子的可能数字交集
      Set<int>? intersection;
      for (final cage in relevantCages) {
        final possibleDigits = cagePossibleDigits[cage]!;
        if (intersection == null) {
          intersection = possibleDigits;
        } else {
          intersection = intersection.intersection(possibleDigits);
        }
        // 如果交集为空，提前退出
        if (intersection.isEmpty) break;
      }
      
      if (intersection != null && intersection.isNotEmpty) {
        // 与候选数取交集
        final newSet = oldSet.intersection(intersection);
        if (newSet.length != oldSet.length) {
          context.setCandidates(r, c, newSet);
          changed = true;
        }
      }
      // 注意：如果交集为空，不应该清空候选数
      // 交集为空只是表示没有共同的约束数字，而不是矛盾
    }
    return changed;
  }
  
  /// 获取笼子的所有可能数字集合
  Set<int> _getPossibleDigitsForCage(BoardContext context, KillerCage cage) {
    final cells = cage.cellCoordinates;
    final sum = cage.sum;
    
    final filled = <int>{};
    int filledSum = 0;
    final emptyIndices = <int>[];
    final emptyCandidates = <Set<int>>[];

    for (int i = 0; i < cells.length; i++) {
      final (r, c) = cells[i];
      final val = context.board.getCell(r, c).value;
      if (val != null) {
        filled.add(val);
        filledSum += val;
      } else {
        emptyIndices.add(i);
        emptyCandidates.add(context.getCandidates(r, c));
      }
    }

    final remainingSum = sum - filledSum;
    if (remainingSum < 0 || emptyIndices.isEmpty) {
      return <int>{};
    }

    if (emptyIndices.length > 5) {
      // 对于大笼子，返回所有可能的数字（基于基本约束）
      final maxNumber = context.board.getMaxNumber();
      final possibleDigits = <int>{};
      for (int digit = 1; digit <= maxNumber; digit++) {
        if (!filled.contains(digit)) {
          possibleDigits.add(digit);
        }
      }
      return possibleDigits;
    }

    // 对于小笼，计算所有可能的数字
    final possibleDigits = <int>{};
    
    final maxNumber = context.board.getMaxNumber();
    for (int digit = 1; digit <= maxNumber; digit++) {
      if (filled.contains(digit)) continue;
      if (KillerCombinationChecker.existsCombination(
        emptyIndices.length,
        remainingSum,
        filled,
        emptyCandidates,
        digit, // 强制包含当前数字
      )) {
        possibleDigits.add(digit);
      }
    }
    
    return possibleDigits;
  }
}

/// 杀手数独笼子区块策略
class KillerCageBlockingStrategy extends Strategy {
  const KillerCageBlockingStrategy();

  @override
  StrategyType get type => StrategyType.killerCageBlocking;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => {GameType.killer};

  @override
  bool apply(BoardContext context) {
    final cages = context.killerCages;
    if (cages == null) return false;

    bool changed = false;
    for (final cage in cages) {
      if (_applyCageBlocking(context, cage)) changed = true;
    }
    return changed;
  }

  bool _applyCageBlocking(BoardContext context, KillerCage cage) {
    final cells = cage.cellCoordinates;
    if (cells.isEmpty) return false;

    // 检查笼子是否在同一行、同一列或同一宫
    final firstRow = cells.first.$1;
    final firstCol = cells.first.$2;
    final firstBlock = (firstRow ~/ 3) * 3 + (firstCol ~/ 3);
    final sameRow = cells.every((c) => c.$1 == firstRow);
    final sameCol = cells.every((c) => c.$2 == firstCol);
    final sameBlock = cells.every((c) => (c.$1 ~/ 3) * 3 + (c.$2 ~/ 3) == firstBlock);
    if (!sameRow && !sameCol && !sameBlock) return false;

    // 获取笼子所有合法组合
    final combos = _getCageCombos(context, cage);
    if (combos == null) return false;
    
    // 处理矛盾情况
    if (combos.isEmpty) {
      // 矛盾：没有合法组合，清空笼子内所有空单元格的候选数
      for (final (r, c) in cells) {
        if (context.board.getCell(r, c).value == null) {
          context.setCandidates(r, c, <int>{});
        }
      }
      return true;
    }

    // 计算所有组合的交集（必然出现的数字）
    Set<int>? commonDigits;
    for (final combo in combos) {
      if (commonDigits == null) {
        commonDigits = Set.from(combo);
      } else {
        commonDigits.retainAll(combo);
      }
      // 如果交集为空，提前退出
      if (commonDigits.isEmpty) break;
    }
    if (commonDigits == null || commonDigits.isEmpty) return false;

    // 收集需要排除的单元格
    final modifications = <(int, int, Set<int>)>[];
    if (sameRow) {
      final row = firstRow;
      for (int c = 0; c < context.size; c++) {
        if (cells.any((cell) => cell.$2 == c)) continue; // 跳过笼子内格子
        final oldSet = context.getCandidates(row, c).toSet();
        final newSet = oldSet.difference(commonDigits);
        if (newSet.length != oldSet.length) {
          modifications.add((row, c, newSet));
        }
      }
    } else if (sameCol) {
      final col = firstCol;
      for (int r = 0; r < context.size; r++) {
        if (cells.any((cell) => cell.$1 == r)) continue;
        final oldSet = context.getCandidates(r, col).toSet();
        final newSet = oldSet.difference(commonDigits);
        if (newSet.length != oldSet.length) {
          modifications.add((r, col, newSet));
        }
      }
    } else if (sameBlock) {
      final blockRow = firstRow ~/ 3;
      final blockCol = firstCol ~/ 3;
      for (int r = blockRow * 3; r < (blockRow + 1) * 3; r++) {
        for (int c = blockCol * 3; c < (blockCol + 1) * 3; c++) {
          if (cells.any((cell) => cell.$1 == r && cell.$2 == c)) continue;
          final oldSet = context.getCandidates(r, c).toSet();
          final newSet = oldSet.difference(commonDigits);
          if (newSet.length != oldSet.length) {
            modifications.add((r, c, newSet));
          }
        }
      }
    }

    if (modifications.isEmpty) return false;

    // 应用修改（无需验证，因为交集数字必然在笼子内，排除不会导致矛盾）
    for (final (r, c, newSet) in modifications) {
      context.setCandidates(r, c, newSet);
    }
    return true;
  }

  /// 获取笼子的所有合法组合（使用组合检查器）
  Set<Set<int>>? _getCageCombos(BoardContext context, KillerCage cage) {
    final sum = cage.sum;
    final cells = cage.cellCoordinates;
    final filled = <int>{};
    int filledSum = 0;
    final emptyIndices = <int>[];
    final emptyCandidates = <Set<int>>[];

    for (int i = 0; i < cells.length; i++) {
      final (r, c) = cells[i];
      final val = context.board.getCell(r, c).value;
      if (val != null) {
        filled.add(val);
        filledSum += val;
      } else {
        emptyIndices.add(i);
        emptyCandidates.add(context.getCandidates(r, c));
      }
    }

    final remainingSum = sum - filledSum;
    
    // 处理剩余和为0的情况
    if (remainingSum < 0) {
      // 矛盾：和为负数，返回空集合
      return <Set<int>>{};
    }
    if (remainingSum == 0) {
      if (emptyIndices.isNotEmpty) {
        // 矛盾：和为0但有未填单元格，返回空集合
        return <Set<int>>{};
      }
      // 和为0且没有空单元格，笼子已填满
      return null;
    }

    if (emptyIndices.isEmpty) return null;

    // 如果空单元格太多，跳过（避免性能问题）
    if (emptyIndices.length > 5) return null;

    // 枚举所有排列（全顺序）
    final combos = <Set<int>>{};
    const maxComboCount = 100; // 限制最大组合数
    _enumeratePermutations(
      0,
      emptyIndices.length,
      remainingSum,
      filled,
      <int>[],
      combos,
      emptyCandidates,
      maxComboCount,
    );
    return combos.isEmpty ? null : combos;
  }

  /// 枚举所有可能的排列
  bool _enumeratePermutations(
    int index,
    int k,
    int targetSum,
    Set<int> used,
    List<int> current,
    Set<Set<int>> result,
    List<Set<int>> emptyCandidates,
    int maxComboCount,
  ) {
    if (index == k) {
      if (targetSum == 0) {
        result.add(current.toSet());
      }
      return result.length >= maxComboCount;
    }
    
    final candidates = emptyCandidates[index];
    for (int num = 1; num <= 9; num++) {
      if (!candidates.contains(num)) continue;
      if (used.contains(num)) continue;
      if (num > targetSum) continue;
      
      current.add(num);
      final newUsed = Set<int>.from(used)..add(num);
      
      final shouldStop = _enumeratePermutations(
        index + 1,
        k,
        targetSum - num,
        newUsed,
        current,
        result,
        emptyCandidates,
        maxComboCount,
      );
      
      current.removeLast();
      
      if (shouldStop) return true;
    }
    
    return false;
  }
}
