import 'package:sudoku/index.dart';

abstract class GameInputHost<B extends Board> {
  GameState<B> get gameState;
  bool get isPlaying;

  Future<void> setCellValue(int row, int col, int? value);
  Future<void> toggleCandidate(int row, int col, int candidate);
  Future<void> clearCellValue();
}

/// 用户输入控制器
///
/// 把键盘输入、数字/候选值设置与清空逻辑从 ViewModel 中拆离，
/// 让页面层和状态层只依赖统一输入入口。
class GameInputController<B extends Board> {
  GameInputController(this._host);

  final GameInputHost<B> _host;

  Future<void> inputNumber(int number) async {
    final selected = _host.gameState.getSelectedCell();
    if (selected == null || !_host.isPlaying) return;

    final value = number;
    if (_host.gameState.isMarkMode) {
      await _host.toggleCandidate(selected.row, selected.col, value);
      return;
    }

    await _host.setCellValue(selected.row, selected.col, value);
  }

  Future<void> setValueByNumber(int? value) async {
    if (!_host.isPlaying) return;

    final selectedCell = _host.gameState.getSelectedCell();
    if (selectedCell == null) return;

    if (_host.gameState.isMarkMode && value != null) {
      await _host.toggleCandidate(selectedCell.row, selectedCell.col, value);
      return;
    }

    await _host.setCellValue(selectedCell.row, selectedCell.col, value);
  }

  Future<void> clearSelectedCell() async {
    final selectedCell = _host.gameState.getSelectedCell();
    if (selectedCell == null || !_host.isPlaying) return;
    await _host.clearCellValue();
  }
}
