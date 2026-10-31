import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/index.dart';
import 'package:sudoku/renderers/layout_calculator.dart';

class GameBoardArea<B extends Board> extends StatelessWidget {
  const GameBoardArea({
    super.key,
    required this.viewModel,
    required this.layout,
    required this.availableWidth,
    required this.availableHeight,
    required this.boardBuilder,
    required this.numberKeyboardBuilder,
    required this.functionKeyboardBuilder,
  });

  final GameViewModel<B> viewModel;
  final GameLayout layout;
  final double availableWidth;
  final double availableHeight;
  final Widget Function(BuildContext context, GameViewModel<B> viewModel, double cellSize) boardBuilder;
  final Widget Function(BuildContext context, GameViewModel<B> viewModel, double buttonSize) numberKeyboardBuilder;
  final Widget Function(BuildContext context, GameViewModel<B> viewModel, double buttonSize) functionKeyboardBuilder;

  @override
  Widget build(BuildContext context) {
    final boardOffset = _boardOffset();
    final keypadOffset = _keypadOffset();

    if (layout.isHorizontalLayout) {
      return Stack(
        children: [
          Positioned(
            left: boardOffset.dx,
            top: boardOffset.dy,
            child: Selector<GameViewModel<B>, (Board, Board?, bool, int, bool)>(
              selector: (_, vm) => (
                vm.currentGameState.board,
                vm.currentGameState.solution,
                vm.isOverviewMode,
                vm.currentSubGridIndex,
                vm.currentGameState.isShowingSolution,
              ),
              builder: (_, data, _) => SizedBox(
                width: layout.boardSize,
                height: layout.boardSize,
                child: boardBuilder(context, viewModel, layout.boardCellSize),
              ),
            ),
          ),
          Positioned(
            left: keypadOffset.dx,
            top: keypadOffset.dy,
            child: Selector<GameViewModel<B>, (Board, bool, bool, bool, bool, bool, bool)>(
              selector: (_, vm) => (
                vm.currentGameState.board,
                vm.isPlaying,
                vm.currentGameState.isShowingSolution,
                vm.currentGameState.isMarkMode,
                vm.currentGameState.isAutoMarkMode,
                vm.canUndo,
                vm.canRedo,
              ),
              builder: (_, data, _) => SizedBox(
                width: layout.keypadWidth,
                height: layout.keypadHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: layout.keypadHeight / 2,
                      child: numberKeyboardBuilder(context, viewModel, layout.keypadCellSize),
                    ),
                    SizedBox(
                      height: layout.keypadHeight / 2,
                      child: functionKeyboardBuilder(context, viewModel, layout.keypadCellSize),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned(
          left: boardOffset.dx,
          top: boardOffset.dy,
          child: Selector<GameViewModel<B>, (Board, Board?, bool, int, bool)>(
            selector: (_, vm) => (
              vm.currentGameState.board,
              vm.currentGameState.solution,
              vm.isOverviewMode,
              vm.currentSubGridIndex,
              vm.currentGameState.isShowingSolution,
            ),
            builder: (_, data, _) => SizedBox(
              width: layout.boardSize,
              height: layout.boardSize,
              child: boardBuilder(context, viewModel, layout.boardCellSize),
            ),
          ),
        ),
        Positioned(
          left: keypadOffset.dx,
          top: keypadOffset.dy,
          child: Selector<GameViewModel<B>, (Board, bool, bool, bool, bool, bool, bool)>(
            selector: (_, vm) => (
              vm.currentGameState.board,
              vm.isPlaying,
              vm.currentGameState.isShowingSolution,
              vm.currentGameState.isMarkMode,
              vm.currentGameState.isAutoMarkMode,
              vm.canUndo,
              vm.canRedo,
            ),
            builder: (_, data, _) => SizedBox(
              width: layout.keypadWidth,
              height: layout.keypadHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: layout.keypadWidth / 2,
                    child: numberKeyboardBuilder(context, viewModel, layout.keypadCellSize),
                  ),
                  SizedBox(
                    width: layout.keypadWidth / 2,
                    child: functionKeyboardBuilder(context, viewModel, layout.keypadCellSize),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Offset _boardOffset() {
    if (layout.isHorizontalLayout) {
      return Offset(
        (availableWidth - layout.boardSize - LayoutCalculator.spacing - layout.keypadWidth) / 2,
        (availableHeight - layout.boardSize) / 2,
      );
    }

    return Offset(
      (availableWidth - layout.boardSize) / 2,
      (availableHeight - layout.boardSize - LayoutCalculator.spacing - layout.keypadHeight) / 2,
    );
  }

  Offset _keypadOffset() {
    if (layout.isHorizontalLayout) {
      return Offset(
        _boardOffset().dx + layout.boardSize + LayoutCalculator.spacing,
        (availableHeight - layout.keypadHeight) / 2,
      );
    }

    return Offset(
      (availableWidth - layout.keypadWidth) / 2,
      (availableHeight - layout.boardSize - LayoutCalculator.spacing - layout.keypadHeight - LayoutCalculator.keypadBottomMargin) / 2 + layout.boardSize + LayoutCalculator.spacing,
    );
  }
}
