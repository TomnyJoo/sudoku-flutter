import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/game_state.dart';

abstract class GameMutationHost<B extends Board> {
  GameState<B> get gameState;
  bool get isPlaying;

  Future<void> setCellValueInternal(int row, int col, int? value);
  Future<void> toggleCandidateInternal(int row, int col, int candidate);
  Future<void> clearCellInternal(int row, int col);
}

/// 游戏状态变更协调器
///
/// 把重复的单元格 mutation 流程集中在这里，避免 GameViewModel
/// 一边管理生命周期，一边承担大量重复状态更新细节。
class GameMutationController<B extends Board> {
  GameMutationController({
    required GameMutationHost<B> owner,
    required Future<void> Function({bool shouldSave}) finalizeMutation,
    required void Function(String message, Object error) onError,
  })  : _owner = owner,
        _finalizeMutation = finalizeMutation,
        _onError = onError;

  final GameMutationHost<B> _owner;
  final Future<void> Function({bool shouldSave}) _finalizeMutation;
  final void Function(String message, Object error) _onError;

  Future<void> setCellValue(int row, int col, int? value) async {
    if (!_owner.isPlaying) return;
    try {
      await _owner.setCellValueInternal(row, col, value);
      await _finalizeMutation();
    } catch (e) {
      _onError('设置单元格值失败', e);
    }
  }

  Future<void> toggleCandidate(int row, int col, int candidate) async {
    if (!_owner.isPlaying) return;
    try {
      await _owner.toggleCandidateInternal(row, col, candidate);
      await _finalizeMutation();
    } catch (e) {
      _onError('切换候选数失败', e);
    }
  }

  Future<void> clearCellValue() async {
    final selectedCell = _owner.gameState.getSelectedCell();
    if (selectedCell == null) return;

    try {
      await _owner.clearCellInternal(selectedCell.row, selectedCell.col);
      await _finalizeMutation();
    } catch (e) {
      _onError('清除单元格值失败', e);
    }
  }
}
