import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 单网格 Samurai 棋盘的左右滑动导航组件。
class SamuraiSwipeableBoard<B extends Board> extends StatefulWidget {
  const SamuraiSwipeableBoard({
    required this.viewModel,
    required this.cellSize,
    super.key,
  });

  final GameViewModel<B> viewModel;
  final double cellSize;

  @override
  State<SamuraiSwipeableBoard<B>> createState() => _SamuraiSwipeableBoardState<B>();
}

class _SamuraiSwipeableBoardState<B extends Board> extends State<SamuraiSwipeableBoard<B>> {
  static const double _swipeThreshold = 50.0;

  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    final currentIndex = widget.viewModel.currentSubGridIndex;

    if (details.primaryVelocity != null) {
      if (details.primaryVelocity! < -_swipeThreshold) {
        final nextIndex = (currentIndex + 1) % 5;
        await widget.viewModel.switchSubGrid(nextIndex);
      } else if (details.primaryVelocity! > _swipeThreshold) {
        final prevIndex = (currentIndex - 1 + 5) % 5;
        await widget.viewModel.switchSubGrid(prevIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: SamuraiBoardWidget(
          board: widget.viewModel.state.board as SamuraiBoard,
          solution: widget.viewModel.state.solution as SamuraiBoard,
          isShowingSolution: widget.viewModel.state.isShowingSolution,
          currentSubGridIndex: widget.viewModel.currentSubGridIndex,
          onCellSelected: (Cell cell) => widget.viewModel.selectCellByObject(cell),
          cellSize: widget.cellSize,
        ),
      );
}
