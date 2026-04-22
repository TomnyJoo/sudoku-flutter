import 'package:flutter/foundation.dart';
import 'package:sudoku/index.dart';

mixin GameStateMixin<B extends Board, T extends GameState<B>> on ChangeNotifier {
  GameState<B> get gameState;
  set gameState(GameState<B> value);
  
  GameTimer get gameTimer;
  GameService<B> get gameService;
  
  void updateGameState(GameState<B> newState) {
    gameState = newState;
    notifyListeners();
  }
  
  bool get isPlaying => gameState.startTime != null && !gameState.isCompleted;
  bool get isPaused => gameState.startTime != null && !gameState.isCompleted && gameTimer.isPaused;
  bool get isCompleted => gameState.isCompleted;
  Duration get elapsedTime => Duration(seconds: gameState.elapsedTime);
  bool get isMarkMode => gameState.isMarkMode;
  bool get isAutoMarkMode => gameState.isAutoMarkMode;
  bool get showSolution => gameState.isShowingSolution;
  double get completionPercentage => gameState.completionPercentage;
  int get errorCount => gameState.mistakes;
  
  Future<void> toggleMarkMode() async {
    updateGameState(gameState.copyWith(isMarkMode: !gameState.isMarkMode));
  }
  
  Future<void> toggleAutoMarkMode() async {
    updateGameState(gameState.copyWith(isAutoMarkMode: !gameState.isAutoMarkMode));
  }
  
  Future<void> toggleShowSolution() async {
    if (gameState.isShowingSolution) {
      updateGameState(gameService.hideSolution(gameState));
    } else {
      updateGameState(gameService.showSolution(gameState));
    }
  }
  
  Future<void> resetGame() async {
    updateGameState(gameService.resetGameState(gameState));
  }
}
