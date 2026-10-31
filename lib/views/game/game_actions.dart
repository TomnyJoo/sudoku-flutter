import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 页面级动作协调器
///
/// 统一收口和屏幕相关的状态动作，避免页面类直接散落大量委托逻辑。
class GameActions<B extends Board> {
  const GameActions(this.viewModel);

  final GameViewModel<B> viewModel;

  Future<void> handleBackNavigation(BuildContext context) async {
    await viewModel.saveGameBlocking();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void toggleOverviewMode() => viewModel.toggleOverviewMode();

  Future<void> switchSubGrid(int index) => viewModel.switchSubGrid(index);
}
