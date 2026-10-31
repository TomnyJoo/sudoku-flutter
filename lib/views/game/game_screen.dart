import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/index.dart';
import 'package:sudoku/main.dart';
import 'package:sudoku/renderers/layout_calculator.dart';

/// 统一游戏屏幕页面
///
/// 通过构造函数参数接收游戏类型配置，支持所有6种游戏类型
class GameScreen<B extends Board> extends StatefulWidget {
  const GameScreen({super.key, this.autoLoadSavedGame = true});
  final bool autoLoadSavedGame;

  @override
  State<GameScreen<B>> createState() => GameScreenState<B>();
}

class GameScreenState<B extends Board> extends State<GameScreen<B>>
    with WidgetsBindingObserver {
  late GameViewModel<B> _viewModel;
  late GameActions<B> _pageActions;

  // Diagonal 特有状态
  bool _showDiagonalLines = true;

  // Jigsaw 特有状态
  bool _showRegionNumbers = true;

  bool _hasNavigatedToFinish = false;

  bool get _isDiagonalGame => _viewModel.gameService.gameType == 'diagonal';
  bool get _isJigsawGame => _viewModel.gameService.gameType == 'jigsaw';
  bool get _isSamuraiGame => _viewModel.gameService.gameType == 'samurai';

  String get _gameType => _viewModel.gameService.gameType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appSettings = context.read<AppSettings>();
      final audioManager = AudioManager()
        ..setMusicEnabled(appSettings.musicEnabled)
        ..soundEffectEnabled = appSettings.soundEffectsEnabled;
      if (appSettings.musicEnabled && !audioManager.isMusicPlaying) {
        audioManager.playMusic();
      }
    });
    _viewModel = Provider.of<GameViewModel<B>>(context, listen: false);
    _pageActions = GameActions<B>(_viewModel);
    _viewModel.addListener(_onGameStateChanged);
    _hasNavigatedToFinish = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNavigation();
    });
  }

  void _handleInitialNavigation() {
    final args = ModalRoute.of(context)?.settings.arguments;

    // 如果参数是 GameState，直接使用该状态（从保存游戏列表加载）
    if (args is GameState<B>) {
      _viewModel.loadGameState(args);
      return;
    }

    // 如果参数是 Difficulty，开始新游戏（兼容旧方式）
    if (args is Difficulty) {
      _viewModel.startNewGame(args);
      return;
    }

    // 如果参数是 GameRouteArgs，提取 gameType 信息
    if (args is GameRouteArgs) {
      if (args.initialState != null && args.initialState is GameState<B>) {
        _viewModel.loadGameState(args.initialState as GameState<B>);
        return;
      }
      if (args.difficulty != null) {
        _viewModel.startNewGame(args.difficulty!);
        return;
      }
    }

    // 如果没有参数，尝试加载保存的游戏
    if (widget.autoLoadSavedGame) {
      _loadSavedGame();
    }
  }

  Future<void> _loadSavedGame() async {
    await _viewModel.loadGame();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      await _viewModel.saveGameBlocking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_onGameStateChanged);
    if (_viewModel.isLoading) {
      _viewModel.cancelGameGeneration();
    }
    unawaited(_viewModel.saveGameBlocking());
    _viewModel.pauseGame(notify: false);
    super.dispose();
  }

  // ========== 标题和路由配置 ==========

  String _getTitle(BuildContext context) {
    final gameLocalizations = LocalizationUtils.game(context);
    switch (_gameType) {
      case 'standard':
        return gameLocalizations.gameTypeStandardName;
      case 'diagonal':
        return gameLocalizations.gameTypeDiagonalName;
      case 'window':
        return gameLocalizations.gameTypeWindowName;
      case 'jigsaw':
        return gameLocalizations.gameTypeJigsawName;
      case 'killer':
        return gameLocalizations.gameTypeKillerName;
      case 'samurai':
        return gameLocalizations.gameTypeSamuraiName;
      default:
        return '';
    }
  }

  String get _settingsRoute => AppConstants.settingsRoute;

  // ========== 构建方法 ==========

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _viewModel.saveGameBlocking().then((_) {
            if (mounted) {
              navigator.pop();
            }
          });
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight;

          // 竖屏时 body 顶部还要被状态栏占用，估算可用区域时一并扣除，
          // 避免按全屏高度估算导致棋盘与键盘整体下移、压到屏幕底部
          final gameAreaWidth = availableWidth;
          final gameAreaHeight =
              availableHeight -
              kToolbarHeight -
              MediaQuery.of(context).padding.top -
              AppConstants.gameAreaHeightOffset;

          final layout = LayoutCalculator.calculateStandardLayout(
            Size(gameAreaWidth, gameAreaHeight),
          );

          final isDarkMode = context.isDarkMode;

          return Scaffold(
            appBar: !layout.isHorizontalLayout
                ? GameHeaderBar(
                    title: _getTitle(context),
                    actions: _buildTitleActions(context),
                    onBackPressed: () =>
                        _pageActions.handleBackNavigation(context),
                    onHelpPressed: _showGameRules,
                    onSettingsPressed: () => _showSettings(context),
                    isDarkMode: isDarkMode,
                  )
                : null,
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? AppColors.homeBackgroundGradientDark
                      : AppColors.homeBackgroundGradientLight,
                ),
              ),
              child: SafeArea(
                // 顶部由 AppBar 处理，这里只保留底部/侧边安全区，
                // 防止上下布局的键盘底部落入 Android 系统手势/导航区域
                top: false,
                child: _buildGameLayout(context, layout),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建标题栏的额外操作按钮
  List<Widget>? _buildTitleActions(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final iconColor = isDarkMode
        ? Colors.white.withAlpha(200)
        : AppColors.mutedText;

    if (_isDiagonalGame) {
      final diagonalIconColor = _showDiagonalLines
          ? context.primaryColor
          : iconColor;
      return [
        IconButton(
          icon: Icon(
            _showDiagonalLines ? Icons.show_chart : Icons.show_chart_outlined,
            color: diagonalIconColor,
          ),
          onPressed: () {
            setState(() {
              _showDiagonalLines = !_showDiagonalLines;
            });
          },
          tooltip: _showDiagonalLines
              ? LocalizationUtils.app(context).hideDiagonalLines
              : LocalizationUtils.app(context).showDiagonalLines,
        ),
      ];
    }

    if (_isJigsawGame) {
      final jigsawIconColor = _showRegionNumbers
          ? context.primaryColor
          : iconColor;
      return [
        IconButton(
          icon: Icon(
            _showRegionNumbers ? Icons.grid_on : Icons.grid_off,
            color: jigsawIconColor,
          ),
          onPressed: () {
            setState(() {
              _showRegionNumbers = !_showRegionNumbers;
            });
          },
          tooltip: _showRegionNumbers
              ? LocalizationUtils.app(context).hideRegionNumbers
              : LocalizationUtils.app(context).showRegionNumbers,
        ),
      ];
    }

    if (_isSamuraiGame) {
      return [
        Selector<GameViewModel<B>, (int, bool)>(
          selector: (_, vm) => (vm.currentSubGridIndex, vm.isOverviewMode),
          builder: (_, data, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildSamuraiTitleActions(
              context,
              iconColor,
              data.$1,
              data.$2,
            ),
          ),
        ),
      ];
    }

    return null;
  }

  /// 构建 Samurai 子网格导航按钮
  List<Widget> _buildSamuraiTitleActions(
    BuildContext context,
    Color iconColor,
    int currentIndex,
    bool isOverviewMode,
  ) {
    final subGridNames = LocalizationUtils.app(context).subGridNames;

    return [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final prevIndex = (currentIndex - 1 + 5) % 5;
                    await _viewModel.switchSubGrid(prevIndex);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_left,
                      size: 18,
                      color: iconColor.withAlpha(200),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  subGridNames[currentIndex],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor.withAlpha(200),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final nextIndex = (currentIndex + 1) % 5;
                    await _viewModel.switchSubGrid(nextIndex);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: iconColor.withAlpha(200),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 4),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pageActions.toggleOverviewMode(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isOverviewMode
                  ? iconColor.withAlpha(50)
                  : iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOverviewMode ? Icons.zoom_in : Icons.zoom_out_map,
              size: 18,
              color: iconColor.withAlpha(200),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildGameLayout(BuildContext context, GameLayout layout) =>
      Selector<GameViewModel<B>, bool>(
    selector: (_, vm) => vm.isLoading,
    builder: (context, isLoading, _) {
      if (isLoading) {
        return _buildLoadingIndicator(context);
      }

      if (layout.isHorizontalLayout) {
        return Column(
          children: [
            _buildTopToolbar(context),
            _buildStatsBar(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => _buildGameArea(
                  context,
                  LayoutCalculator.calculateHorizontalLayout(
                    constraints.biggest,
                  ),
                  constraints,
                ),
              ),
            ),
          ],
        );
      } else {
        return Column(
          children: [
            _buildStatsBar(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => _buildGameArea(
                  context,
                  LayoutCalculator.calculateVerticalLayout(constraints.biggest),
                  constraints,
                ),
              ),
            ),
          ],
        );
      }
    },
  );

  Widget _buildTopToolbar(BuildContext context) => GameHeaderBar(
    title: _getTitle(context),
    actions: _buildTitleActions(context),
    onBackPressed: () => _pageActions.handleBackNavigation(context),
    onHelpPressed: _showGameRules,
    onSettingsPressed: () => _showSettings(context),
    isDarkMode: context.isDarkMode,
    isHorizontalLayout: true,
  );

  Widget _buildStatsBar(BuildContext context) => GameStatsBar<B>(
    viewModel: _viewModel,
    isSamuraiGame: _isSamuraiGame,
    isDarkMode: context.isDarkMode,
  );

  // ========== 棋盘构建 ==========

  Widget _buildBoard(
    BuildContext context,
    GameViewModel<B> viewModel,
    double cellSize,
  ) {
    if (_isSamuraiGame) {
      return _buildSamuraiBoard(context, viewModel, cellSize);
    }

    return NineByNineBoardWidget(
      board: viewModel.state.board,
      onCellSelected: (Cell cell) => viewModel.selectCellByObject(cell),
      cellSize: cellSize,
      showDiagonalLines: _showDiagonalLines,
      showRegionNumbers: _showRegionNumbers,
    );
  }

  Widget _buildSamuraiBoard(
    BuildContext context,
    GameViewModel<B> viewModel,
    double cellSize,
  ) {
    final samuraiBoard = viewModel.state.board;
    final samuraiSolution = viewModel.state.solution;

    if (viewModel.isOverviewMode &&
        samuraiBoard is SamuraiBoard &&
        samuraiSolution is SamuraiBoard) {
      return SamuraiOverviewBoard(
        board: samuraiBoard,
        solution: samuraiSolution,
        isShowingSolution: viewModel.state.isShowingSolution,
        onCellSelected: (Cell cell) => viewModel.selectCellByObject(cell),
        currentSubGridIndex: viewModel.currentSubGridIndex,
        cellSize: cellSize * 0.6,
        onSubGridSelected: (int index) async {
          await _pageActions.switchSubGrid(index);
          viewModel.exitOverviewMode();
        },
      );
    }

    return SamuraiSwipeableBoard<B>(viewModel: viewModel, cellSize: cellSize);
  }

  // ========== 数字键盘和功能键盘 ==========

  Widget _buildNumberKeyboard(
    BuildContext context,
    GameViewModel<B> viewModel,
    double buttonSize,
  ) {
    // 仅当「游戏进行中 + 非答案模式 + 已选中可填写单元格」时键盘才可用，
    // 其余状态下按键会被静默丢弃，用户容易误判为键盘无响应
    final selectedCell = viewModel.currentGameState.getSelectedCell();
    final canInput =
        viewModel.isPlaying &&
        !viewModel.currentGameState.isShowingSolution &&
        selectedCell != null &&
        selectedCell.isEditable;

    return NumberKeyboard(
      onNumberSelected: (int? number) {
        if (number != null) {
          viewModel.setCellValueByNumber(number);
        }
      },
      buttonSize: buttonSize,
      getNumberCount: (context, number) => viewModel.getNumberCount(number),
      isEnabled: canInput,
    );
  }

  Widget _buildFunctionKeyboard(
    BuildContext context,
    GameViewModel<B> viewModel,
    double buttonSize,
  ) => FunctionKeyboard(
    onUndo: viewModel.undo,
    onRedo: viewModel.redo,
    onHint: () => viewModel.hint(),
    onMark: viewModel.toggleMarkMode,
    onErase: viewModel.clearCellValue,
    onReset: viewModel.resetGame,
    onAutoMark: viewModel.toggleAutoMarkMode,
    onSolution: viewModel.toggleShowSolution,
    onNew: () {
      confirmNewGame(context, viewModel);
    },
    buttonSize: buttonSize,
    isMarkMode: () => viewModel.currentGameState.isMarkMode,
    isAutoMarkMode: () => viewModel.currentGameState.isAutoMarkMode,
    canUndo: () => viewModel.canUndo,
    canRedo: () => viewModel.canRedo,
    isShowingSolution: () => viewModel.currentGameState.isShowingSolution,
  );

  // ========== 游戏区域布局 ==========

  Widget _buildGameArea(
    BuildContext context,
    GameLayout layout,
    BoxConstraints constraints,
  ) {
    final viewModel = Provider.of<GameViewModel<B>>(context);

    return GameBoardArea<B>(
      viewModel: viewModel,
      layout: layout,
      availableWidth: constraints.maxWidth,
      availableHeight: constraints.maxHeight,
      boardBuilder: _buildBoard,
      numberKeyboardBuilder: _buildNumberKeyboard,
      functionKeyboardBuilder: _buildFunctionKeyboard,
    );
  }

  // ========== 游戏状态变化处理 ==========

  void _onGameStateChanged() {
    if (_viewModel.currentGameState.isCompleted &&
        !_viewModel.showSolution &&
        !_hasNavigatedToFinish) {
      _hasNavigatedToFinish = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChangeNotifierProvider<GameViewModel<B>>.value(
                    value: _viewModel,
                    child: CompletionScreenFactory.create(_gameType),
                  ),
            ),
          );
        }
      });
    }
  }

  // ========== 对话框 ==========

  void _showSettings(BuildContext context) {
    GameDialogs.showSettings(context, _settingsRoute);
  }

  void _showGameRules() {
    GameDialogs.showGameRules(context);
  }

  void confirmNewGame(BuildContext context, GameViewModel<B> gameVM) {
    GameDialogs.confirmNewGame(context, gameVM, (difficulty) async {
      await gameVM.startNewGame(difficulty);
    });
  }

  Widget _buildLoadingIndicator(BuildContext context) => AnimatedBuilder(
    animation: _viewModel,
    builder: (context, child) {
      String progressText = '';
      final customProgress = GameUtils.getProgressText(
        context,
        _viewModel.generationStage,
      );
      if (customProgress != null) {
        progressText = customProgress;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
            const SizedBox(height: AppConstants.spacingHuge),
            Text(
              LocalizationUtils.app(context).generatingGame,
              style: TextStyle(
                fontSize: AppTextStyles.fontSizeBody,
                color: context.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            if (progressText.isNotEmpty)
              Text(
                progressText,
                style: TextStyle(
                  fontSize: AppTextStyles.fontSizeLabel,
                  fontWeight: FontWeight.w500,
                  color: context.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            const SizedBox(height: AppConstants.spacingMaximum),
            ElevatedButton.icon(
              onPressed: () {
                _viewModel.cancelGameGeneration();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close),
              label: Text(
                LocalizationUtils.app(context).cancel,
                style: const TextStyle(
                  fontSize: AppTextStyles.fontSizeBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMaximum,
                  vertical: AppConstants.spacingLarge,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.spacingHuge),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      );
    },
  );
}
