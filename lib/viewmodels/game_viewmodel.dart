import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 统一游戏视图模型
///
/// 负责游戏的核心逻辑和状态管理，通过混入（Mixin）实现各种功能
/// 泛型 B 表示棋盘类型
class GameViewModel<B extends Board> extends ChangeNotifier
    with
        GameStateMixin<B, GameState<B>>,
        GameLifecycleMixin<B, GameState<B>>,
        GameInputMixin<B, GameState<B>>,
        GameAssistMixin<B, GameState<B>>,
        GamePersistenceMixin<B, GameState<B>>
    implements GameMutationHost<B>, GameInputHost<B>, SamuraiModeHost<B> {
  /// 构造游戏视图模型
  ///
  /// [gameType] - 游戏类型标识符
  /// [boardFromJson] - 棋盘 JSON 反序列化函数
  /// [createEmptyBoard] - 创建空棋盘的工厂函数
  /// [settings] - 应用设置（可选）
  /// [regionMatrix] - 区域矩阵（仅 Jigsaw 使用）
  GameViewModel({
    required String gameType,
    required B Function(Map<String, dynamic>) boardFromJson,
    required B Function() createEmptyBoard,
    AppSettings? settings,
    List<List<int>>? regionMatrix,
    GameValidator? validator,
  })  : _gameType = gameType,
        _createEmptyBoard = createEmptyBoard,
        _regionMatrix = regionMatrix,
        _gameService = GameService<B>(
          gameType: gameType,
          validator: validator ?? GameValidator(),
          boardFromJson: boardFromJson,
        ),
        _gameState = _createInitialState<B>(createEmptyBoard(), regionMatrix),
        _appSettings = settings {
    _mutationController = GameMutationController<B>(
      owner: this,
      finalizeMutation: _finalizeBoardMutation,
      onError: _handleError,
    );
    _bestScoreController = GameBestScoreController(
      gameType: gameType,
      onChanged: notifyListeners,
    );
    _inputController = GameInputController<B>(this);
    _samuraiController = SamuraiModeController<B>(this);

    // 初始化游戏计时器
    _gameTimer = GameTimer(
      onTick: () {
        // 游戏未完成时更新计时
        if (!gameState.isCompleted) {
          gameState = gameState.copyWith(elapsedTime: _gameTimer.elapsedTime);
          notifyListeners();
        }
      },
      onComplete: () async {
        // 游戏完成时更新状态
        gameState = gameState.copyWith(isCompleted: true);
        notifyListeners();
      },
    );
  }

  /// 从已有状态构造（用于从保存的游戏列表加载）
  GameViewModel.withState({
    required String gameType,
    required B Function(Map<String, dynamic>) boardFromJson,
    required B Function() createEmptyBoard,
    required GameState<B> initialState,
    AppSettings? settings,
    List<List<int>>? regionMatrix,
    GameValidator? validator,
  })  : _gameType = gameType,
        _createEmptyBoard = createEmptyBoard,
        _regionMatrix = regionMatrix,
        _gameService = GameService<B>(
          gameType: gameType,
          validator: validator ?? GameValidator(),
          boardFromJson: boardFromJson,
        ),
        _gameState = initialState,
        _appSettings = settings {
    _mutationController = GameMutationController<B>(
      owner: this,
      finalizeMutation: _finalizeBoardMutation,
      onError: _handleError,
    );
    _bestScoreController = GameBestScoreController(
      gameType: gameType,
      onChanged: notifyListeners,
    );
    _inputController = GameInputController<B>(this);
    _samuraiController = SamuraiModeController<B>(this);

    _gameTimer = GameTimer(
      onTick: () {
        if (!gameState.isCompleted) {
          gameState = gameState.copyWith(elapsedTime: _gameTimer.elapsedTime);
          notifyListeners();
        }
      },
      onComplete: () async {
        gameState = gameState.copyWith(isCompleted: true);
        notifyListeners();
      },
    );
  }

  /// 游戏类型标识符
  final String _gameType;

  /// 创建空棋盘的工厂函数
  final B Function() _createEmptyBoard;

  /// 区域矩阵（仅 Jigsaw 使用）
  final List<List<int>>? _regionMatrix;

  /// 游戏服务
  final GameService<B> _gameService;

  /// 最佳成绩协调器
  late final GameBestScoreController _bestScoreController;

  /// 状态变更协调器
  late final GameMutationController<B> _mutationController;

  /// 用户输入控制器
  late final GameInputController<B> _inputController;

  /// Samurai 状态协调器
  late final SamuraiModeController<B> _samuraiController;

  /// 应用设置
  AppSettings? _appSettings;

  /// 游戏计时器
  late final GameTimer _gameTimer;

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否取消游戏生成
  bool _isCancelled = false;

  /// 游戏生成阶段
  GenerationStage _generationStage = GenerationStage.generatingSolution;

  // ========== Samurai 特有属性 ==========

  /// 是否为 Samurai 游戏
  @override
  bool get isSamuraiGame => _gameType == 'samurai';

  /// 当前子网格索引
  int get currentSubGridIndex => _samuraiController.currentSubGridIndex;

  /// 是否概览模式
  bool get isOverviewMode => _samuraiController.isOverviewMode;

  /// 切换概览模式
  void toggleOverviewMode() => _samuraiController.toggleOverviewMode();

  /// 进入概览模式
  void enterOverviewMode() => _samuraiController.enterOverviewMode();

  /// 退出概览模式
  void exitOverviewMode() => _samuraiController.exitOverviewMode();

  /// 切换子网格
  Future<void> switchSubGrid(int index) async => _samuraiController.switchSubGrid(index);

  /// 创建初始游戏状态（静态方法）
  static GameState<B> _createInitialState<B extends Board>(
    B emptyBoard,
    List<List<int>>? regionMatrix,
  ) {
    final history = HistoryManager(initialBoard: emptyBoard);
    final stats = SessionStatistics(
      board: emptyBoard,
      mistakes: 0,
      totalMoves: 0,
      isCompleted: false,
      elapsedTime: 0,
    );

    return GameState<B>(
      board: emptyBoard,
      initialBoard: emptyBoard,
      solution: emptyBoard,
      difficulty: Difficulty.medium.name,
      history: history,
      stats: stats,
    );
  }

  /// 获取当前难度的最佳成绩（从缓存）
  BestScoreRecord? get cachedBestScore => _bestScoreController.cachedBestScore;

  /// 获取最佳成绩的显示时间
  String? get bestScoreDisplayTime => _bestScoreController.displayTime;

  /// 获取最佳成绩的错误数（无记录时返回 null）
  int? get bestScoreMistakes => _bestScoreController.mistakes;

  /// 最佳成绩是否已加载完成
  bool get isBestScoreLoaded => _bestScoreController.isLoaded;

  /// 加载指定难度的最佳成绩
  @override
  Future<void> loadBestScore([String? difficulty]) => _bestScoreController.load(
    currentDifficulty: gameState.difficulty,
    difficulty: difficulty,
  );

  // Mixin 需要的 getter/setter 实现
  @override
  GameState<B> get gameState => _gameState;

  @override
  set gameState(GameState<B> value) {
    _gameState = value;
  }

  /// 游戏状态
  GameState<B> _gameState;

  /// 获取泛型游戏状态
  GameState<B> get state => _gameState;

  @override
  GameTimer get gameTimer => _gameTimer;

  @override
  GameService<B> get gameService => _gameService;

  @override
  AppSettings? get settings => _appSettings;

  @override
  bool get isPlaying => gameState.startTime != null && !gameState.isCompleted;

  @override
  bool get useAdvancedStrategy => _appSettings?.useAdvancedStrategy ?? true;

  @override
  bool get isLoading => _isLoading;

  @override
  set isLoading(bool value) => _isLoading = value;

  @override
  bool get isCancelled => _isCancelled;

  @override
  set isCancelled(bool value) => _isCancelled = value;

  @override
  GenerationStage get generationStage => _generationStage;

  @override
  set generationStage(GenerationStage value) => _generationStage = value;

  /// 获取当前游戏状态
  GameState<B> get currentGameState => gameState;

  /// 更新游戏设置
  void updateSettings(AppSettings settings) {
    _appSettings = settings;
    onSettingsChanged();
    notifyListeners();
  }

  /// 当设置变化时调用
  @protected
  void onSettingsChanged() {
    unawaited(_refreshAutoMarkCandidatesAfterChange());
  }

  Future<void> _refreshAutoMarkCandidatesAfterChange() async {
    if (!gameState.isAutoMarkMode || !isPlaying) return;

    if (isSamuraiGame) {
      await autoMarkCandidates(visibleSubBoards: [_samuraiController.currentSubGridIndex]);
      return;
    }

    await autoMarkCandidates();
  }

  // ========== 游戏生命周期方法（委托给 Mixin）==========

  /// 开始新游戏
  Future<void> startNewGame(final Difficulty difficulty) =>
      startNewGameInternal(difficulty,
          generateNewGame: generateNewGame,
          resetGameState: resetGameState);

  /// 暂停游戏
  Future<void> pauseGame({bool notify = true}) => pauseGameInternal(notify: notify);

  /// 恢复游戏
  Future<void> resumeGame() => resumeGameInternal();

  /// 保存游戏状态（异步）
  Future<void> saveGame() => saveGameInternal();

  /// 保存游戏状态（同步阻塞，等待保存完成）
  Future<void> saveGameBlocking() => saveGameSyncBlocking();

  /// 加载游戏状态
  Future<void> loadGame() async {
    await loadGameInternal();
    
    if (isSamuraiGame) {
      _samuraiController.resetState();
    }
    
    await loadBestScore();
  }

  /// 加载指定的游戏状态
  void loadGameState(GameState<B> state) {
    gameState = state;
    gameTimer.setElapsedTime(state.elapsedTime);
    if (state.startTime != null && !state.isCompleted) {
      gameTimer.start();
    }
    notifyListeners();
    loadBestScore();
  }

  /// 取消游戏生成
  void cancelGameGeneration() => cancelGameGenerationInternal();

  // ========== 单元格操作方法（委托给 Mixin）==========

  /// 处理单元格点击
  @override
  Future<void> handleCellTap(final int row, final int col) async {
    if (!isPlaying) return;
    try {
      handleCellSelection(row, col);
      notifyListeners();
    } catch (e) {
      _handleError('处理单元格点击失败', e);
    }
  }

  /// 选择单元格
  @override
  void selectCell(final int row, final int col) => handleCellTap(row, col);

  /// 通过 Cell 对象选择单元格
  void selectCellByObject(Cell cell) => handleCellTap(cell.row, cell.col);

  /// 输入数字
  Future<void> inputNumber(final int number) async => _inputController.inputNumber(number);

  /// 同步 Samurai 模式状态
  void _syncSamuraiModeState() {
    if (!isSamuraiGame) return;
    _samuraiController.resetState();
  }

  /// 在状态更新后统一处理自动标记、完成判定和保存
  ///
  /// [valueChanged] 表示本次变更是否改变了单元格的"值"。
  /// 仅值变化（填入/清除数字）才重算候选数；
  /// 纯候选数变化（标记切换、清除标记）不重算，
  /// 避免浪费性能并防止自动重算覆盖手动标记。
  Future<void> _finalizeBoardMutation({
    bool shouldSave = true,
    bool valueChanged = true,
  }) async {
    if (gameState.isCompleted) {
      gameTimer.pause();
      if (PlatformDispatcher.instance.implicitView != null) {
        final audioManager = AudioManager();
        await audioManager.playCompleteSound();
      }
    }

    notifyListeners();

    if (valueChanged) {
      await _refreshAutoMarkCandidatesAfterChange();
    }

    if (shouldSave) {
      await saveGame();
    }
  }

  /// 设置单元格值
  @override
  Future<void> setCellValue(
    final int row,
    final int col,
    final int? value,
  ) async => _mutationController.setCellValue(row, col, value);

  /// 数字输入是否正在处理中（防止快速连点导致异步操作交错执行）
  bool _isNumberInputBusy = false;

  /// 设置当前选中单元格的值
  Future<void> setCellValueByNumber(int? value) async {
    if (!isPlaying || _isNumberInputBusy) return;
    _isNumberInputBusy = true;
    try {
      await _inputController.setValueByNumber(value);
    } finally {
      _isNumberInputBusy = false;
    }
  }

  /// 切换候选数标记
  @override
  Future<void> toggleCandidate(
    final int row,
    final int col,
    final int candidate,
  ) async => _mutationController.toggleCandidate(row, col, candidate);

  /// 清除当前选中单元格的值（有值清值，无值清候选数）
  @override
  Future<void> clearCellValue() async => _mutationController.clearCellValue();

  // ========== 功能键盘相关方法（委托给 Mixin）==========

  /// 是否可以撤销
  bool get canUndo => gameState.history.canUndo();

  /// 是否可以重做
  bool get canRedo => gameState.history.canRedo();

  /// 撤销
  void undo() {
    if (!isPlaying) return;
    gameState = gameService.undo(gameState);
    if (gameState.isAutoMarkMode) {
      autoMarkCandidates();
    }
    notifyListeners();
  }

  /// 重做
  void redo() {
    if (!isPlaying) return;
    gameState = gameService.redo(gameState);
    if (gameState.isAutoMarkMode) {
      autoMarkCandidates();
    }
    notifyListeners();
  }

  /// 提示
  @override
  Future<void> hint() async {
    lastHintMessage = null;
    await super.hint();
    if (lastHintMessage != null) {
      notifyListeners();
    }
  }

  /// 切换标记模式
  @override
  Future<void> toggleMarkMode() async => super.toggleMarkMode();

  /// 切换自动标记模式
  @override
  Future<void> toggleAutoMarkMode() async {
    gameState = gameState.copyWith(isAutoMarkMode: !gameState.isAutoMarkMode);
    notifyListeners();

    if (gameState.isAutoMarkMode && isPlaying) {
      await _refreshAutoMarkCandidatesAfterChange();
    } else if (!gameState.isAutoMarkMode) {
      await clearAllCandidates();
    }
  }

  /// 切换显示答案
  @override
  Future<void> toggleShowSolution() async => super.toggleShowSolution();

  // ========== 核心方法实现 ==========

  /// 生成新游戏
  @protected
  Future<void> generateNewGame(final Difficulty difficulty) async {
    if (isCancelled) return;

    final newState = await gameService.generateGame(
      difficulty: difficulty,
      options: {'isCancelled': () => isCancelled},
      onStageUpdate: (stage) {
        if (!isCancelled) updateGenerationStage(stage);
      },
    );

    if (isCancelled) return;

    gameState = newState;
    _syncSamuraiModeState();
    notifyListeners();
  }

  /// 重置游戏状态
  @protected
  Future<void> resetGameState() async {
    gameState = _createInitialState<B>(_createEmptyBoard(), _regionMatrix);
    _syncSamuraiModeState();
    notifyListeners();
  }

  /// 开始自定义游戏（仅 standard 和 diagonal 支持）
  Future<void> startCustomGame(B initialBoard) async {
    if (_gameType != 'standard' && _gameType != 'diagonal') return;

    final board = initialBoard;
    final solution = initialBoard;
    final history = HistoryManager(initialBoard: board);
    final stats = SessionStatistics(
      board: board,
      mistakes: 0,
      totalMoves: 0,
      isCompleted: false,
      elapsedTime: 0,
    );

    final newState = GameState<B>(
      board: board,
      initialBoard: initialBoard,
      solution: solution,
      difficulty: Difficulty.custom.name,
      history: history,
      stats: stats,
      startTime: DateTime.now(),
    );
    gameState = newState;
    notifyListeners();
  }

  // ========== 工具方法 ==========

  /// 获取数字使用次数
  int? getNumberCount(int number) {
    if (isSamuraiGame) {
      // Samurai 仅计算当前子网格的数字计数
      final samuraiBoard = gameState.board;
      if (samuraiBoard is SamuraiBoard) {
        final subBoard = samuraiBoard.getSubBoard(_samuraiController.currentSubGridIndex);
        int count = 0;
        for (int i = 0; i < subBoard.size; i++) {
          for (int j = 0; j < subBoard.size; j++) {
            if (subBoard.cells[i][j].value == number) {
              count++;
            }
          }
        }
        return count;
      }
    }
    final counts = gameState.board.calculateNumberCounts();
    return counts[number];
  }

  /// 获取本地化的难度字符串
  String getLocalizedDifficulty(BuildContext context) {
    final loc = LocalizationUtils.app(context);
    switch (gameState.difficulty) {
      case 'beginner':
        return loc.difficultyBeginner;
      case 'easy':
        return loc.difficultyEasy;
      case 'medium':
        return loc.difficultyMedium;
      case 'hard':
        return loc.difficultyHard;
      case 'expert':
        return loc.difficultyExpert;
      case 'master':
        return loc.difficultyMaster;
      case 'custom':
        return loc.difficultyCustom;
      default:
        return gameState.difficulty;
    }
  }

  /// 处理错误（内部使用）
  void _handleError(final String message, final Object error) {
    AppLogger.error('$message: $error');
  }

  @override
  Future<void> setCellValueForHint(int row, int col, int value) async {
    if (!isPlaying) return;
    try {
      final newState = gameService.setCellValue(
        gameState: gameState,
        row: row,
        col: col,
        value: value,
        isMarkMode: false,
      );
      gameState = newState;
      await _finalizeBoardMutation();
    } catch (e) {
      _handleError('设置提示值失败', e);
    }
  }

  /// 释放资源
  @override
  void dispose() {
    disposeAutoMarkTimer();
    disposeSaveTimer();
    _gameTimer.dispose();
    super.dispose();
  }
}
