import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 游戏工厂类，负责创建不同类型的游戏服务和生成器
class GameFactory {
  /// 私有构造函数
  GameFactory._();

  /// 创建游戏服务，[gameType] - 游戏类型，[validator] - 游戏验证器
  static GameService createGameService(
    GameType gameType,
    GameValidator validator,
  ) {
    switch (gameType) {
      case GameType.standard:
        return GameService<StandardBoard>(
          gameType: 'standard',
          validator: validator,
          boardFromJson: StandardBoard.fromJson,
        );
      case GameType.diagonal:
        return GameService<DiagonalBoard>(
          gameType: 'diagonal',
          validator: validator,
          boardFromJson: DiagonalBoard.fromJson,
        );
      case GameType.window:
        return GameService<WindowBoard>(
          gameType: 'window',
          validator: validator,
          boardFromJson: WindowBoard.fromJson,
        );
      case GameType.jigsaw:
        return GameService<JigsawBoard>(
          gameType: 'jigsaw',
          validator: validator,
          boardFromJson: JigsawBoard.fromJson,
        );
      case GameType.killer:
        return GameService<KillerBoard>(
          gameType: 'killer',
          validator: validator,
          boardFromJson: KillerBoard.fromJson,
        );
      case GameType.samurai:
        return GameService<SamuraiBoard>(
          gameType: 'samurai',
          validator: validator,
          boardFromJson: SamuraiBoard.fromJson,
        );
    }
  }

  /// 创建游戏生成器，[gameType] - 游戏类型
  static dynamic createGameGenerator(GameType gameType) {
    switch (gameType) {
      case GameType.standard:
        return StandardGenerator();
      case GameType.diagonal:
        return DiagonalGenerator();
      case GameType.window:
        return WindowGenerator();
      case GameType.jigsaw:
        return JigsawGenerator();
      case GameType.killer:
        return KillerGenerator();
      case GameType.samurai:
        return SamuraiGenerator();
    }
  }

  /// 获取游戏类型对应的路由名称
  static String getGameRoute(GameType gameType) => '/game';

  /// 获取本地化的游戏名称
  static String getLocalizedGameName(GameType gameType, dynamic localizations) {
    try {
      return gameType.getLocalizedName(localizations);
    } catch (e) {
      return GameConfig().getGameConfig(gameType)?['name'] as String? ?? gameType.toString().split('.').last;
    }
  }

  /// 获取游戏图标
  static IconData getGameIcon(GameType gameType) => GameConfig().getGameIcon(gameType);

  /// 获取游戏颜色
  static Color getGameColor(GameType gameType) => GameConfig().getGameColor(gameType);

  /// 是否显示自定义游戏
  static bool showCustomGame(GameType gameType) => GameConfig().showCustomGame(gameType);

  /// 获取游戏难度级别
  static List<String> getDifficultyLevels(GameType gameType) => GameConfig().getDifficultyLevels(gameType);

  /// 获取自定义游戏路由
  static String? getCustomGameRoute(GameType gameType) => GameConfig().getCustomGameRoute(gameType);

  /// 获取游戏名称本地化键
  static String? getGameNameLocalizationKey(GameType gameType) => GameConfig().getGameNameLocalizationKey(gameType);

  /// 获取游戏描述本地化键
  static String? getGameDescriptionLocalizationKey(GameType gameType) => GameConfig().getGameDescriptionLocalizationKey(gameType);

  /// 获取游戏规则本地化键
  static String? getGameRulesLocalizationKey(GameType gameType) => GameConfig().getGameRulesLocalizationKey(gameType);

  /// 获取游戏验证规则
  static Map<String, dynamic>? getGameValidationRules(GameType gameType) => GameConfig().getGameValidationRules(gameType);

  /// 获取游戏生成参数
  static Map<String, dynamic>? getGameGenerationParams(GameType gameType) => GameConfig().getGameGenerationParams(gameType);

  /// 获取游戏难度参数
  static Map<String, dynamic>? getGameDifficultyParams(GameType gameType) => GameConfig().getGameDifficultyParams(gameType);

  /// 获取特定难度的参数
  static Map<String, dynamic>? getDifficultyParams(GameType gameType, String difficulty) => GameConfig().getDifficultyParams(gameType, difficulty);

  /// 获取游戏UI配置
  static Map<String, dynamic>? getGameUIConfig(GameType gameType) => GameConfig().getGameUIConfig(gameType);

  /// 创建游戏验证器
  static GameValidator createGameValidator(GameType gameType) => GameValidator();
}
