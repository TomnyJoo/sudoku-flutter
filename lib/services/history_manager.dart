import 'package:sudoku/models/board.dart';

/// 历史记录管理器，负责管理游戏状态的历史记录
class HistoryManager {

  /// 创建历史记录管理器
  const HistoryManager({
    required this.states,
    required this.currentIndex,
    this.maxSize = 50,
  });

  /// 创建带有初始状态的历史记录管理器
  factory HistoryManager.withInitialState(Board initialState, {int maxSize = 50}) => HistoryManager(
        states: [initialState],
        currentIndex: 0,
        maxSize: maxSize,
      );

  /// 创建空的历史记录管理器
  factory HistoryManager.empty({int maxSize = 50}) => HistoryManager(
        states: [],
        currentIndex: -1,
        maxSize: maxSize,
      );
  final List<Board> states;
  final int currentIndex;
  final int maxSize;

  /// 添加新状态到历史记录
  HistoryManager addState(Board newState) {
    // 如果当前不在历史记录的末尾，截断历史记录
    final newStates = states.sublist(0, currentIndex + 1)..add(newState);
    
    // 限制历史记录大小
    int newIndex = newStates.length - 1;
    if (newStates.length > maxSize) {
      newStates.removeAt(0);
      newIndex--;
    }

    return HistoryManager(
      states: newStates,
      currentIndex: newIndex,
      maxSize: maxSize,
    );
  }

  /// 撤销操作，返回上一个状态
  (HistoryManager, Board?) undo() {
    if (currentIndex <= 0) {
      return (this, null);
    }

    final newIndex = currentIndex - 1;
    final newHistory = HistoryManager(
      states: states,
      currentIndex: newIndex,
      maxSize: maxSize,
    );

    return (newHistory, states[newIndex]);
  }

  /// 重做操作，返回下一个状态
  (HistoryManager, Board?) redo() {
    if (currentIndex >= states.length - 1) {
      return (this, null);
    }

    final newIndex = currentIndex + 1;
    final newHistory = HistoryManager(
      states: states,
      currentIndex: newIndex,
      maxSize: maxSize,
    );

    return (newHistory, states[newIndex]);
  }

  /// 检查是否可以撤销
  bool canUndo() => currentIndex > 0;

  /// 检查是否可以重做
  bool canRedo() => currentIndex < states.length - 1;

  /// 清空历史记录，只保留当前状态
  HistoryManager clear() {
    if (states.isEmpty) {
      return this;
    }

    return HistoryManager(
      states: [states[currentIndex]],
      currentIndex: 0,
      maxSize: maxSize,
    );
  }

  /// 获取当前状态
  Board? get currentState {
    if (states.isEmpty || currentIndex < 0) {
      return null;
    }
    return states[currentIndex];
  }

  /// 获取历史记录长度
  int get length => states.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryManager &&
        other.states == states &&
        other.currentIndex == currentIndex &&
        other.maxSize == maxSize;
  }

  @override
  int get hashCode => Object.hash(states, currentIndex, maxSize);

  @override
  String toString() => 'HistoryManager(states: ${states.length}, currentIndex: $currentIndex, maxSize: $maxSize)';
}
