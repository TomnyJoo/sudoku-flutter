import 'package:flutter/material.dart';
import 'package:sudoku/constants/app_constants.dart';
import 'package:sudoku/renderers/layout_strategy.dart';

class GameLayout {
  GameLayout({
    required this.boardCellSize,
    required this.keypadCellSize,
    required this.isHorizontalLayout,
    required this.boardSize,
    required this.keypadWidth,
    required this.keypadHeight,
    required this.totalWidth,
    required this.totalHeight,
    required this.utilizationRatio,
  });

  final double boardCellSize;
  final double keypadCellSize;
  final bool isHorizontalLayout;
  final double boardSize;
  final double keypadWidth;
  final double keypadHeight;
  final double totalWidth;
  final double totalHeight;
  final double utilizationRatio;

  @override
  String toString() => 'GameLayout{布局: ${isHorizontalLayout ? '左右' : '上下'}, '
        '棋盘单元格: ${boardCellSize.toStringAsFixed(1)}, '
        '棋盘尺寸: ${boardSize.toStringAsFixed(1)}, '
        '键盘区: ${keypadWidth.toStringAsFixed(1)}×${keypadHeight.toStringAsFixed(1)}, '
        '利用率: ${(utilizationRatio * 100).toStringAsFixed(1)}%}';
}

class LayoutCalculator {
  /// 布局间距（引用 AppConstants）
  static const double spacing = AppConstants.spacingMedium;

  /// 最小棋盘单元格尺寸（与 AppConstants 统一）
  static const double minBoardCellSize = AppConstants.minCellSize;

  /// 最小键盘单元格尺寸
  static const double minKeypadCellSize = AppConstants.minKeypadCellSize;

  /// 键盘容器内边距
  static const double keypadContainerPadding = AppConstants.keyboardPadding;

  /// 键盘网格间距
  static const double keypadGridSpacing = AppConstants.keyboardButtonSpacing;

  /// 键盘底部外边距
  static const double keypadBottomMargin = AppConstants.keypadBottomMargin;

  /// 键盘水平外边距默认值（实际值来自用户设置，见 AppSettings.screenEdgeMargin）
  static const double keypadHorizontalMargin = AppConstants.keypadHorizontalMargin;

  static GameLayout calculateOptimalLayout(
    final Size gameAreaSize, {
    int boardSize = 9,
    double edgeMargin = keypadHorizontalMargin,
  }) {
    final strategy = gameAreaSize.width >= gameAreaSize.height
        ? const HorizontalLayoutStrategy()
        : const VerticalLayoutStrategy();
    return strategy.calculate(
      gameAreaSize,
      boardSize: boardSize,
      edgeMargin: edgeMargin,
    );
  }

  static GameLayout _calculateVerticalLayout(
    final double width,
    final double height,
    final int boardSize,
    final double edgeMargin,
  ) =>
      const VerticalLayoutStrategy().calculate(
        Size(width, height),
        boardSize: boardSize,
        edgeMargin: edgeMargin,
      );

  static GameLayout _calculateHorizontalLayout(
    final double width,
    final double height,
    final int boardSize,
    final double edgeMargin,
  ) =>
      const HorizontalLayoutStrategy().calculate(
        Size(width, height),
        boardSize: boardSize,
        edgeMargin: edgeMargin,
      );

  /// 按指定尺寸强制计算左右布局（用于与实际可用区域保持方向一致）
  static GameLayout calculateHorizontalLayout(
    final Size availableSize, {
    final int boardSize = 9,
    final double edgeMargin = keypadHorizontalMargin,
  }) =>
      _calculateHorizontalLayout(
        availableSize.width,
        availableSize.height,
        boardSize,
        edgeMargin,
      );

  /// 按指定尺寸强制计算上下布局（用于与实际可用区域保持方向一致）
  static GameLayout calculateVerticalLayout(
    final Size availableSize, {
    final int boardSize = 9,
    final double edgeMargin = keypadHorizontalMargin,
  }) =>
      _calculateVerticalLayout(
        availableSize.width,
        availableSize.height,
        boardSize,
        edgeMargin,
      );

  static GameLayout calculateStandardLayout(
    final Size availableSize, {
    final double edgeMargin = keypadHorizontalMargin,
  }) =>
    calculateOptimalLayout(availableSize, edgeMargin: edgeMargin);
}
