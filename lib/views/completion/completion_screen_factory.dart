import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/index.dart';

/// Creates the correctly typed completion screen for a game type.
class CompletionScreenFactory {
  const CompletionScreenFactory._();

  static Widget create(String gameType) {
    switch (gameType) {
      case 'standard':
        return _build<StandardBoard>(gameType, StandardBoard.fromJson);
      case 'diagonal':
        return _build<DiagonalBoard>(gameType, DiagonalBoard.fromJson);
      case 'window':
        return _build<WindowBoard>(gameType, WindowBoard.fromJson);
      case 'jigsaw':
        return _build<JigsawBoard>(gameType, JigsawBoard.fromJson);
      case 'killer':
        return _build<KillerBoard>(gameType, KillerBoard.fromJson);
      case 'samurai':
        return _build<SamuraiBoard>(gameType, SamuraiBoard.fromJson);
      default:
        return _build<StandardBoard>(gameType, StandardBoard.fromJson);
    }
  }

  static Widget _build<T extends Board>(
    String gameType,
    T Function(Map<String, dynamic>) boardFromJson,
  ) => CompletionScreen<GameViewModel<T>, GameService<T>, T>(
    gameType: gameType,
    getViewModel: (context) => context.read<GameViewModel<T>>(),
    getGameService: (context) => GameService<T>(
      gameType: gameType,
      validator: GameValidator(),
      boardFromJson: boardFromJson,
    ),
  );
}
