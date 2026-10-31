import 'package:sudoku/index.dart';

abstract class SamuraiModeHost<B extends Board> {
  bool get isSamuraiGame;
  bool get isPlaying;
  GameState<B> get gameState;

  void notifyListeners();

  Future<void> autoMarkCandidates({List<int>? visibleSubBoards});
}

/// Samurai 专用状态与交互协调器
///
/// 将子网格索引、概览模式，以及 Samurai 独有的切换逻辑从通用视图模型中拆出，
/// 保持主控制器只负责游戏主流程协调。
class SamuraiModeController<B extends Board> {
  SamuraiModeController(this._host);

  final SamuraiModeHost<B> _host;

  int _currentSubGridIndex = 4;
  bool _isOverviewMode = false;

  int get currentSubGridIndex => _currentSubGridIndex;
  bool get isOverviewMode => _isOverviewMode;

  void resetState() {
    _currentSubGridIndex = 4;
    _isOverviewMode = false;
  }

  void toggleOverviewMode() {
    _isOverviewMode = !_isOverviewMode;
    _host.notifyListeners();
  }

  void enterOverviewMode() {
    if (!_isOverviewMode) {
      _isOverviewMode = true;
      _host.notifyListeners();
    }
  }

  void exitOverviewMode() {
    if (_isOverviewMode) {
      _isOverviewMode = false;
      _host.notifyListeners();
    }
  }

  Future<void> switchSubGrid(int index) async {
    _currentSubGridIndex = index;
    _host.notifyListeners();

    if (_host.gameState.isAutoMarkMode && _host.isPlaying) {
      await _host.autoMarkCandidates(visibleSubBoards: [index]);
    }
  }
}
