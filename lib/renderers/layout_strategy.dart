import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku/renderers/layout_calculator.dart';

abstract class GameLayoutStrategy {
  const GameLayoutStrategy();

  GameLayout calculate(
    Size gameAreaSize, {
    int boardSize = 9,
    double edgeMargin = LayoutCalculator.keypadHorizontalMargin,
  });
}

class HorizontalLayoutStrategy extends GameLayoutStrategy {
  const HorizontalLayoutStrategy();

  @override
  GameLayout calculate(
    Size gameAreaSize, {
    int boardSize = 9,
    double edgeMargin = LayoutCalculator.keypadHorizontalMargin,
  }) {
    final width = gameAreaSize.width;
    final height = gameAreaSize.height;

    // 先按自然尺寸（不含边距）计算，再统一向内收缩边距。
    // 若只在宽度约束中扣除边距，高度受限时（宽屏/横屏）边距将完全不可见。
    var boardPixelSize = (width - LayoutCalculator.spacing) / 1.5;
    if (boardPixelSize > height) {
      boardPixelSize = height;
    }
    boardPixelSize = max(0.0, boardPixelSize - edgeMargin * 2);

    final keypadHeight = boardPixelSize;
    final keypadWidth = boardPixelSize * 0.5;
    final boardCellSize = boardPixelSize / boardSize;

    final eachKeypadWidth = keypadWidth;
    final eachKeypadHeight = keypadHeight / 2;

    final keypadCellSizeByWidth = (eachKeypadWidth - LayoutCalculator.keypadContainerPadding * 2 - LayoutCalculator.keypadGridSpacing * 2) / 3;
    final keypadCellSizeByHeight = (eachKeypadHeight - LayoutCalculator.keypadContainerPadding * 2 - LayoutCalculator.keypadGridSpacing * 2) / 3;

    final keypadCellSize = min(keypadCellSizeByWidth, keypadCellSizeByHeight);

    final totalWidth = boardPixelSize + LayoutCalculator.spacing + keypadWidth;
    final totalHeight = boardPixelSize;
    final utilizationRatio = (boardPixelSize * boardPixelSize + keypadWidth * keypadHeight) / (width * height);

    return GameLayout(
      boardCellSize: boardCellSize,
      keypadCellSize: keypadCellSize,
      isHorizontalLayout: true,
      boardSize: boardPixelSize,
      keypadWidth: keypadWidth,
      keypadHeight: keypadHeight,
      totalWidth: totalWidth,
      totalHeight: totalHeight,
      utilizationRatio: utilizationRatio,
    );
  }
}

class VerticalLayoutStrategy extends GameLayoutStrategy {
  const VerticalLayoutStrategy();

  @override
  GameLayout calculate(
    Size gameAreaSize, {
    int boardSize = 9,
    double edgeMargin = LayoutCalculator.keypadHorizontalMargin,
  }) {
    final width = gameAreaSize.width;
    final height = gameAreaSize.height;

    // 与横屏策略一致：先求自然尺寸再内缩边距，保证边距始终可见生效
    var boardPixelSize = (height - LayoutCalculator.spacing - LayoutCalculator.keypadBottomMargin) / 1.5;
    if (boardPixelSize > width) {
      boardPixelSize = width;
    }
    boardPixelSize = max(0.0, boardPixelSize - edgeMargin * 2);

    final keypadWidth = boardPixelSize;
    final keypadHeight = boardPixelSize * 0.5;
    final boardCellSize = boardPixelSize / boardSize;

    final eachKeypadWidth = keypadWidth / 2;
    final eachKeypadHeight = keypadHeight;

    final keypadCellSizeByWidth = (eachKeypadWidth - LayoutCalculator.keypadContainerPadding * 2 - LayoutCalculator.keypadGridSpacing * 2) / 3;
    final keypadCellSizeByHeight = (eachKeypadHeight - LayoutCalculator.keypadContainerPadding * 2 - LayoutCalculator.keypadGridSpacing * 2) / 3;

    final keypadCellSize = min(keypadCellSizeByWidth, keypadCellSizeByHeight);

    final totalHeight = boardPixelSize + LayoutCalculator.spacing + keypadHeight + LayoutCalculator.keypadBottomMargin;
    final totalWidth = boardPixelSize;
    final utilizationRatio = (boardPixelSize * boardPixelSize + keypadWidth * keypadHeight) / (width * height);

    return GameLayout(
      boardCellSize: boardCellSize,
      keypadCellSize: keypadCellSize,
      isHorizontalLayout: false,
      boardSize: boardPixelSize,
      keypadWidth: keypadWidth,
      keypadHeight: keypadHeight,
      totalWidth: totalWidth,
      totalHeight: totalHeight,
      utilizationRatio: utilizationRatio,
    );
  }
}

class StandardGameLayoutStrategy extends GameLayoutStrategy {
  const StandardGameLayoutStrategy();

  @override
  GameLayout calculate(
    Size gameAreaSize, {
    int boardSize = 9,
    double edgeMargin = LayoutCalculator.keypadHorizontalMargin,
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
}
