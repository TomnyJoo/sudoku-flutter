import 'package:flutter/foundation.dart';
import 'package:sudoku/index.dart';

/// Loads and exposes the best score for one game type.
class GameBestScoreController {
  GameBestScoreController({
    required this.gameType,
    required VoidCallback onChanged,
  }) : _onChanged = onChanged;

  final String gameType;
  final VoidCallback _onChanged;

  BestScoreRecord? _cachedBestScore;
  bool isLoaded = false;

  BestScoreRecord? get cachedBestScore => _cachedBestScore;

  String? get displayTime {
    if (!isLoaded) return null;
    final score = _cachedBestScore;
    if (score == null || score.time <= 0) return null;
    return GameUtils.formatTime(score.time);
  }

  int? get mistakes => _cachedBestScore?.mistakes;

  Future<void> load({required String currentDifficulty, String? difficulty}) async {
    try {
      final targetDifficulty = difficulty ?? currentDifficulty;
      if (targetDifficulty.isEmpty) {
        _cachedBestScore = null;
        isLoaded = true;
        _onChanged();
        return;
      }

      final statistics = await StatisticsManager.getGameStatistics(gameType);
      _cachedBestScore = statistics.difficultyStats[targetDifficulty]?.bestScoreRecord;
      isLoaded = true;
      _onChanged();
    } catch (error, stackTrace) {
      AppLogger.error('加载最佳成绩失败: $error\n$stackTrace');
      _cachedBestScore = null;
      isLoaded = true;
      _onChanged();
    }
  }
}
