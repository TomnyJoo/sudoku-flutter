import 'package:flutter/material.dart';
import 'package:sudoku/theme/app_colors.dart';
import 'package:sudoku/theme/theme_extension.dart';

/// Palette data extracted before board painting.
class BoardColors {
  const BoardColors({
    required this.isDarkMode,
    required this.boardSelectedCellColor,
    required this.boardHighlightedCellColor,
    required this.boardCellBackgroundColor,
    required this.boardFixedValueColor,
    required this.boardUserValueColor,
    required this.errorColor,
    required this.boardMarkerColor,
    required this.boardGridLineColor,
    required this.boardGridLineBoldColor,
    required this.boardRegionColors,
    required this.boardRegionNumberColor,
    required this.primaryColor,
    required this.boardWindowBackgroundColor,
  });

  factory BoardColors.fromContext(BuildContext context) => BoardColors(
        isDarkMode: context.isDarkMode,
        boardSelectedCellColor: context.boardSelectedCellColor,
        boardHighlightedCellColor: context.boardHighlightedCellColor,
        boardCellBackgroundColor: context.boardCellBackgroundColor,
        boardFixedValueColor: context.boardFixedValueColor,
        boardUserValueColor: context.boardUserValueColor,
        errorColor: context.errorColor,
        boardMarkerColor: context.boardMarkerColor,
        boardGridLineColor: context.boardGridLineColor,
        boardGridLineBoldColor: context.boardGridLineBoldColor,
        boardRegionColors: context.boardRegionColors,
        boardRegionNumberColor: context.boardRegionNumberColor,
        primaryColor: context.primaryColor,
        boardWindowBackgroundColor: context.boardWindowBackgroundColor,
      );

  final bool isDarkMode;
  final Color boardSelectedCellColor;
  final Color boardHighlightedCellColor;
  final Color boardCellBackgroundColor;
  final Color boardFixedValueColor;
  final Color boardUserValueColor;
  final Color errorColor;
  final Color boardMarkerColor;
  final Color boardGridLineColor;
  final Color boardGridLineBoldColor;
  final List<Color> boardRegionColors;
  final Color boardRegionNumberColor;
  final Color primaryColor;
  final Color boardWindowBackgroundColor;

  Color getBoardCageColor(int colorIndex) =>
      AppColors.getBoardCageColor(isDarkMode, colorIndex);
}
