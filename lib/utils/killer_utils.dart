import 'package:sudoku/models/index.dart';

/// Killer Sudoku 工具类
///
/// 提供cage相关的公共方法，减少代码重复
class KillerUtils {
  /// 获取cage中的所有格子
  static List<Cell> getCageCells(KillerBoard board, KillerCage cage) => cage
      .cellCoordinates
      .map((coord) => board.getCell(coord.$1, coord.$2))
      .toList();

  /// 获取cage中已填充的格子
  static List<Cell> getFilledCells(KillerBoard board, KillerCage cage) =>
      getCageCells(board, cage).where((cell) => cell.value != null).toList();

  /// 获取cage中未填充的格子
  static List<Cell> getEmptyCells(KillerBoard board, KillerCage cage) =>
      getCageCells(board, cage).where((cell) => cell.value == null).toList();

  /// 计算n个格子的最小可能和
  /// 使用最小的n个不同数字：1+2+...+n
  static int minSum(int n) => n * (n + 1) ~/ 2;

  /// 计算n个格子的最大可能和
  /// 使用最大的n个不同数字：9+8+...+(9-n+1)
  static int maxSum(int n) => n * (19 - n) ~/ 2;

  /// 计算n个格子的最大可能和（考虑已使用的数字）
  static int maxPossibleSum(int n, List<int> usedNumbers) {
    final available =
        List.generate(
            9,
            (i) => i + 1,
          ).where((number) => !usedNumbers.contains(number)).toList()
          ..sort((a, b) => b.compareTo(a));

    return available.take(n).fold(0, (s, number) => s + number);
  }

  /// 检查cage的和值约束是否可满足
  static bool isCageSumSatisfiable(KillerBoard board, KillerCage cage) {
    final filledCells = getFilledCells(board, cage);
    final emptyCells = getEmptyCells(board, cage);

    if (filledCells.isEmpty) return true;

    final currentSum = filledCells.fold<int>(0, (s, c) => s + (c.value ?? 0));
    final remainingSum = cage.sum - currentSum;

    final emptyCount = emptyCells.length;
    final minPossible = minSum(emptyCount);

    final usedNumbers = filledCells.map((c) => c.value!).toList();
    final maxPossible = maxPossibleSum(emptyCount, usedNumbers);

    return remainingSum >= minPossible && remainingSum <= maxPossible;
  }

  /// 检查cage内是否有重复数字
  static bool hasDuplicateNumbers(KillerBoard board, KillerCage cage) {
    final filledCells = getFilledCells(board, cage);
    final numbers = filledCells.map((cell) => cell.value).toList();
    final uniqueNumbers = Set<int?>.from(numbers);
    return uniqueNumbers.length != numbers.length;
  }

  /// 获取cage内已使用的数字集合
  static Set<int> getUsedNumbers(KillerBoard board, KillerCage cage) =>
      getFilledCells(board, cage).map((cell) => cell.value!).toSet();

  /// 检查cage是否完成（所有格子都已填充）
  static bool isCageComplete(KillerBoard board, KillerCage cage) =>
      getEmptyCells(board, cage).isEmpty;

  /// 验证cage是否有效
  static bool isCageValid(
    KillerBoard board,
    KillerCage cage, {
    bool checkDuplicate = true,
  }) {
    final currentSum = cage.getCurrentSum(board);

    if (currentSum > cage.sum) return false;

    if (checkDuplicate && hasDuplicateNumbers(board, cage)) return false;

    if (cage.isComplete(board)) {
      return currentSum == cage.sum;
    }

    return true;
  }
}
