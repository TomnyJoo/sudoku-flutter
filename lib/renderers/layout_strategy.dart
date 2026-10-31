import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku/renderers/layout_calculator.dart';

abstract class GameLayoutStrategy {
  const GameLayoutStrategy();

  GameLayout calculate(
    Size gameAreaSize, {
    int boardSize = 9,
  });
}

class HorizontalLayoutStrategy extends GameLayoutStrategy {
  const HorizontalLayoutStrategy();

  @override
  GameLayout calculate(
    Size gameAreaSize, {
    int boardSize = 9,
  }) {
    final width = gameAreaSize.width;
    final height = gameAreaSize.height;
    final availableWidth = width - LayoutCalculator.keypadHorizontalMargin * 2;

    var boardPixelSize = (availableWidth - LayoutCalculator.spacing) / 1.5;
    if (boardPixelSize > height) {
      boardPixelSize = height;
    }

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
  }) {
    final width = gameAreaSize.width;
    final height = gameAreaSize.height;
    final availableWidth = width - LayoutCalculator.keypadHorizontalMargin * 2;

    var boardPixelSize = (height - LayoutCalculator.spacing - LayoutCalculator.keypadBottomMargin) / 1.5;
    if (boardPixelSize > availableWidth) {
      boardPixelSize = availableWidth;
    }

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
  }) {
    final strategy = gameAreaSize.width >= gameAreaSize.height
        ? const HorizontalLayoutStrategy()
        : const VerticalLayoutStrategy();
    return strategy.calculate(gameAreaSize, boardSize: boardSize);
  }
}
