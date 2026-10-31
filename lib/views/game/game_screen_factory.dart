import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku/index.dart';

class GameScreenFactory extends StatelessWidget {
  const GameScreenFactory({
    required this.gameType,
    this.initialState,
    super.key,
  });

  final GameType gameType;
  final Object? initialState;

  @override
  Widget build(BuildContext context) {
    switch (gameType) {
      case GameType.standard:
        return _buildGame<StandardBoard>(
          context,
          gameType: 'standard',
          boardFromJson: StandardBoard.fromJson,
          createEmptyBoard: StandardBoard.empty,
          initialState: _initialStateFor<StandardBoard>(),
        );
      case GameType.diagonal:
        return _buildGame<DiagonalBoard>(
          context,
          gameType: 'diagonal',
          boardFromJson: DiagonalBoard.fromJson,
          createEmptyBoard: DiagonalBoard.empty,
          initialState: _initialStateFor<DiagonalBoard>(),
        );
      case GameType.window:
        return _buildGame<WindowBoard>(
          context,
          gameType: 'window',
          boardFromJson: WindowBoard.fromJson,
          createEmptyBoard: WindowBoard.empty,
          initialState: _initialStateFor<WindowBoard>(),
        );
      case GameType.jigsaw:
        return _buildGame<JigsawBoard>(
          context,
          gameType: 'jigsaw',
          boardFromJson: JigsawBoard.fromJson,
          createEmptyBoard: () => JigsawBoard.empty(
            regionMatrix: List.generate(9, (_) => List.filled(9, 0)),
          ),
          initialState: _initialStateFor<JigsawBoard>(),
        );
      case GameType.killer:
        return _buildGame<KillerBoard>(
          context,
          gameType: 'killer',
          boardFromJson: KillerBoard.fromJson,
          createEmptyBoard: KillerBoard.empty,
          initialState: _initialStateFor<KillerBoard>(),
        );
      case GameType.samurai:
        return _buildGame<SamuraiBoard>(
          context,
          gameType: 'samurai',
          boardFromJson: SamuraiBoard.fromJson,
          createEmptyBoard: SamuraiBoard.empty,
          initialState: _initialStateFor<SamuraiBoard>(),
        );
    }
  }

  GameState<B>? _initialStateFor<B extends Board>() {
    final state = initialState;
    if (state is GameState<B>) return state;
    return null;
  }

  Widget _buildGame<B extends Board>(
    BuildContext context, {
    required String gameType,
    required B Function(Map<String, dynamic>) boardFromJson,
    required B Function() createEmptyBoard,
    required GameState<B>? initialState,
  }) => ChangeNotifierProvider<GameViewModel<B>>(
    create: (context) {
      final settings = context.read<AppSettings>();
      final validator = context.read<GameValidator>();
      if (initialState != null) {
        return GameViewModel<B>.withState(
          gameType: gameType,
          boardFromJson: boardFromJson,
          createEmptyBoard: createEmptyBoard,
          initialState: initialState,
          settings: settings,
          validator: validator,
        );
      }
      return GameViewModel<B>(
        gameType: gameType,
        boardFromJson: boardFromJson,
        createEmptyBoard: createEmptyBoard,
        settings: settings,
        validator: validator,
      );
    },
    child: GameScreen<B>(),
  );
}
