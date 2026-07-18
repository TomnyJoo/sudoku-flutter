import 'package:sudoku/models/difficulty.dart';
import 'package:sudoku/models/game_type.dart';
import 'package:sudoku/models/generation_contracts.dart';

/// Web 平台的 Isolate 生成器 Stub
///
/// Web 平台不支持 dart:isolate，使用此 stub 替代
class IsolateGameGenerator {
  Future<GenerationResult> generate({
    required GameType gameType,
    required Difficulty difficulty,
    required int size,
    Function(GenerationStage)? onStageUpdate,
    Map<String, dynamic>? templateData,
  }) async {
    throw UnsupportedError('dart:isolate is not supported on Web platform');
  }

  void cancel() {}
}
