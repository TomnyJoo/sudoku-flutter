import 'dart:math';
import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/game_validator.dart';
import 'package:sudoku/services/solving/solvers/dlx_solver.dart';

/// 杀手数独专用生成器
class KillerGenerator implements IGameGenerator {
  KillerGenerator({
    GameValidator? validator,
    Random? random,
  }) : _validator = validator ?? GameValidator(),
       _random = random ?? Random();
  final GameValidator _validator;
  final Random _random;

  @override
  GameType get supportedGameType => GameType.killer;

  @override
  Future<GenerationResult> generate({
    required Difficulty difficulty,
    required int size,
    bool Function()? isCancelled,
    Map<String, dynamic>? templateData,
    Function(GenerationStage)? onStageUpdate,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 1. 生成标准数独终盘
    Board standardSolution;

    onStageUpdate?.call(GenerationStage.loadingTemplate);

    // 优先使用传入的模板数据
    if (templateData != null && templateData.containsKey('solutionData')) {
      final solutionData = (templateData['solutionData'] as List)
          .map((row) => (row as List).map((v) => v as int?).toList())
          .toList();
      standardSolution = _createStandardBoardFromTemplate(solutionData);
    } else {
      // 备用：使用 DLX 求解器生成
      onStageUpdate?.call(GenerationStage.generatingSolution);
      final solver = StandardDLXSolver.create(random: _random);
      final board = solver.generateSolution(isCancelled: isCancelled);
      if (board == null) {
        throw GameGenerationException('无法生成标准数独终盘');
      }
      standardSolution = board;
    }

    // 2. 加载笼子模板
    List<KillerCage> cageTemplates;

    // 必须使用传入的模板数据
    if (templateData != null && templateData.containsKey('cages')) {
      final cagesJson = templateData['cages'] as List;
      cageTemplates = cagesJson
          .map((cageJson) => KillerCage.fromJson(cageJson as Map<String, dynamic>))
          .toList();
    } else {
      throw GameGenerationException('无法加载笼子模板：模板数据未传递');
    }

    if (cageTemplates.isEmpty) {
      throw GameGenerationException('无法加载笼子模板：模板数据为空');
    }

    // 3. 从终盘计算每个笼子的sum值
    final cagesWithSum = <KillerCage>[];
    int cageIndex = 0;
    for (final cage in cageTemplates) {
      int sum = 0;
      for (final coord in cage.cellCoordinates) {
        final value = standardSolution.getCell(coord.$1, coord.$2).value;
        if (value != null) {
          sum += value;
        }
      }

      final cageWithSum = KillerCage(
        id: 'cage_${DateTime.now().millisecondsSinceEpoch}_$cageIndex',
        cellCoordinates: cage.cellCoordinates,
        sum: sum,
      );
      cagesWithSum.add(cageWithSum);
      cageIndex++;
    }

    // 4. 生成空面板作为谜题
    final emptyCells = List.generate(
      size,
      (row) =>
          List.generate(size, (col) => Cell(row: row, col: col)),
    );

    // 5. 创建谜题棋盘
    final puzzle = KillerBoard(
      size: size,
      cells: emptyCells,
      cages: cagesWithSum,
    );

    // 6. 创建杀手数独终盘
    final solutionCells = List.generate(size, (row) => List.generate(size, (col) {
        final value = standardSolution.getCell(row, col).value;
        return Cell(row: row, col: col, value: value);
      }));

    final killerSolution = KillerBoard(
      size: size,
      cells: solutionCells,
      cages: cagesWithSum,
    );

    // 7. 创建所有区域
    onStageUpdate?.call(GenerationStage.creatingRegions);
    final puzzleRegions = puzzle.createRegions();
    final solutionRegions = killerSolution.createRegions();

    // 8. 更新棋盘区域
    final finalPuzzle = KillerBoard(
      size: size,
      cells: emptyCells,
      regions: puzzleRegions,
      cages: cagesWithSum,
    );

    final finalKillerSolution = KillerBoard(
      size: size,
      cells: solutionCells,
      regions: solutionRegions,
      cages: cagesWithSum,
    );

    // 验证谜题与答案匹配
    onStageUpdate?.call(GenerationStage.validating);
    if (!_validator.validatePuzzleSolution(finalPuzzle, finalKillerSolution)) {
      throw GameGenerationNoSolutionException('游戏验证失败');
    }

    stopwatch.stop();

    return GenerationResult(
      solution: finalKillerSolution,
      puzzle: finalPuzzle,
      generationTime: stopwatch.elapsed,
      usedTemplate: true,
    );
  }

  /// 从模板数据创建标准数独棋盘
  StandardBoard _createStandardBoardFromTemplate(List<List<int?>> data) {
    final size = data.length;

    final cells = List.generate(size, (row) => List.generate(size, (col) {
        final value = data[row][col];
        return Cell(
          row: row,
          col: col,
          value: value == 0 ? null : value,
          isFixed: value != 0,
        );
      }));

    return StandardBoard(size: size, cells: cells);
  }
}
