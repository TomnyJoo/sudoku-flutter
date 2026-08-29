# Sudoku 项目文档

## 一、项目概览

Sudoku 是一个基于 Flutter 的跨平台数独游戏应用，支持多种数独变体，提供流畅的游戏体验和丰富的功能。采用 MVVM 架构，分层清晰，易于扩展。

### 支持的游戏类型

| 类型    | 标识       | 说明                                   |
|--------|------------|---------------------------------------|
| 标准    | `standard` | 经典 9×9 数独                          |
| 对角线  | `diagonal` | 增加两条对角线约束                       |
| 窗口    | `window`   | 增加窗口区域约束                        |
| 锯齿    | `jigsaw`   | 异形宫格，需要模板数据                   |
| 杀手    | `killer`   | 笼子求和约束，需要模板数据                |
| 武士    | `samurai`  | 五个 9×9 子盘联动，21×21 棋盘            |

### 技术栈

- Flutter + Dart
- Provider 状态管理
- SharedPreferences 本地存储
- Isolate 异步生成（避免 UI 卡顿）
- DLX 算法（确保唯一解）

## 二、项目架构

### 目录结构

```
lib/
├── di/              # 依赖注入
├── exceptions/      # 异常处理
├── l10n/            # 国际化资源
├── models/          # 数据模型层（Board、GameType、GameState 等）
├── services/        # 业务逻辑层（生成器、验证器、存储服务）
│   ├── generation/  # 谜题生成子模块
│   ├── solving/     # 求解器子模块
│   │   ├── solvers/ # 具体求解器实现
│   │   └── strategies/ # 解题策略
│   └── statistics/  # 统计服务子模块
├── theme/           # 主题配置（颜色、字体、暗黑模式）
├── utils/           # 工具类
│   ├── constants/   # 常量定义
│   └── validators/  # 验证器工具
├── viewmodels/      # ViewModel 层（MVVM 模式）
│   └── mixins/      # ViewModel 功能混入
├── views/           # UI 视图层
│   ├── components/  # 通用组件（棋盘、按钮、对话框）
│   │   └── boards/  # 棋盘绘制组件
│   └── statistics/  # 统计页面子组件
├── app_initializer.dart  # 应用初始化
├── index.dart       # 模块导出
└── main.dart        # 应用入口

assets/
├── config/          # JSON 配置文件（游戏类型、难度）
├── icon/            # 应用图标
├── images/          # 图片资源
├── l10n/            # 国际化 ARB 文件
├── music/           # 音频资源
└── log.md           # 项目日志文档
```

### 核心设计模式

- **MVVM**：Model（Board、Cell、GameState）→ ViewModel（GameViewModel）→ View（GameScreen、HomeScreen）
- **工厂模式**：GameFactory 创建 GameService 和 Generator；GameGenerator 注册分发到具体生成器
- **策略模式**：IGameGenerator 接口，每种游戏类型实现各自的生成策略；DiggingAlgorithm 接口，支持随机和对称挖空
- **门面模式**：PuzzleGenerator 是最高层入口，处理模板加载和 Isolate 调度
- **适配器模式**：JigsawDlxSolverAdapter 将 JigsawBitSolver 适配为 DLXSudokuSolver 接口

## 三、核心模块说明

### 3.1 棋盘模型（Board）

Board 是所有棋盘类型的抽象基类，定义在 `lib/models/board.dart` 中。每种游戏类型对应一个子类：

| 子类          | gameType   | 特殊属性                                   |
|---------------|------------|--------------------------------------------|
| StandardBoard | `standard` | 无                                         |
| DiagonalBoard | `diagonal` | 通过 regions 添加对角线约束                |
| WindowBoard   | `window`   | 通过 regions 添加窗口约束                  |
| JigsawBoard   | `jigsaw`   | regionMatrix（异形宫格矩阵）              |
| KillerBoard   | `killer`   | cages（笼子列表）                          |
| SamuraiBoard  | `samurai`  | 固定size=21，subGridOffsets 引用 SamuraiConstants |

每个子类必须实现：构造函数、`fromJson`、`createInstance`、`createRegions`、`empty()`、`toJson`、`gameType` getter。

### 3.2 生成器（Generator）

所有生成器实现 `IGameGenerator` 接口（定义在 `lib/models/generation_contracts.dart`）：

```dart
abstract class IGameGenerator {
  GameType get supportedGameType;
  Future<GenerationResult> generate({
    required Difficulty difficulty,
    required int size,
    bool Function()? isCancelled,
    Map<String, dynamic>? templateData,
    Function(GenerationStage)? onStageUpdate,
  });
}
```

生成流程：
1. `PuzzleGenerator.generateGame()` → 门面入口
2. `IsolateGameGenerator` → 在独立 Isolate 中执行
3. `GameGenerator.generate()` → 注册分发
4. 具体生成器（StandardGenerator 等）→ 实际生成
5. 返回 `GenerationResult`（puzzle + solution）

### 3.3 挖空算法（DiggingAlgorithm）

- `SmartRandomDiggingAlgorithm`：随机挖空，保证唯一解
- `SmartSymmetricDiggingAlgorithm`：对称挖空，保证唯一解

挖空流程：`resetFixedCells` → `_randomDigPhase`（挖到中间目标）→ `_smartDigPhase`（挖到最终目标）→ `setFixedCells`

### 3.4 验证器（GameValidator）

完全基于 `Board.regions` 做区域唯一性验证。新游戏类型只要在 Board 子类的 `createRegions()` 中正确创建区域即可自动获得验证支持。

核心方法：
- `validateBoard(Board)` — 遍历所有 region 检查唯一性
- `isValidMove(Board, row, col, value)` — 检查单步移动合法性
- `isGameCompleted(Board)` — 检查是否填满且有效
- `validateKillerCages(KillerBoard)` — Killer 专用笼子验证

### 3.5 存储服务（GameStorageService）

统一管理游戏状态的保存/加载/查询/清除，基于 SharedPreferences。

核心方法：
- `saveGameState(GameState, saveKey)` — 保存
- `loadGameState(saveKey, boardFromJson)` — 加载
- `getSavedGameInfos()` — 查询所有保存的游戏
- `clearGameState(saveKey)` — 清除

### 3.6 求解器

| 求解器          | 文件                     | 用途                                             |
|-----------------|--------------------------|------------------------------------------------|
| BitSolver       | `bit_solver.dart`        | 基于位掩码的快速解计数（Standard/Diagonal/Window） |
| JigsawBitSolver | `jigsaw_bit_solver.dart` | 锯齿数独专用位掩码求解器                           |
| SamuraiBitSolver | `samurai_bit_solver.dart` | 武士数独专用位掩码求解器                         |
| DLXSudokuSolver | `dlx_solver.dart`        | Dancing Links 算法求解器                         |

### 3.7 策略引擎

`StrategyService` 管理解题策略的注册和执行，支持人类解题提示：

| 级别          | 策略                                          |
|---------------|-----------------------------------------------|
| Basic         | NakedSingle、HiddenSingle                     |
| Intermediate  | NakedPair、HiddenPair、LockedCandidate        |
| Advanced      | NakedTriple、HiddenTriple                     |
| Expert        | XWing、Swordfish                              |
| Killer        | CageConstraint、45Rule、OverlapElimination、CageBlocking |

---

## 四、扩展新游戏类型操作指南

以添加"超立方数独"（hyper）为例，说明完整的扩展流程。

### 步骤 1：注册游戏类型

**修改文件：`lib/models/game_type.dart`**

1. 在 `GameType` enum 中添加 `hyper` 值
2. 在 `GameTypeConfigFactory._configs` 中添加配置项：

```dart
GameType.hyper: GameTypeConfig(
  nameKey: 'hyper',
  boardSize: 9,
  supportedRegionTypes: [RegionType.row, RegionType.column, RegionType.block],
  supportsCustomRules: true,
  supportsDifficulty: true,
  iconPath: 'assets/icons/hyper.svg',
  descriptionKey: 'hyper_description',
)
```

### 步骤 2：实现棋盘模型

**修改文件：`lib/models/board.dart`**

在 board.dart 末尾添加 HyperBoard 子类，参考 StandardBoard 的实现，必须实现：
- 构造函数：接受 cells、regions 参数
- `gameType` getter：返回 `'hyper'`
- `createInstance()`：创建新实例
- `createRegions()`：创建行、列、宫格及自定义区域
- `empty()`：返回空棋盘
- `fromJson()` / `toJson()`：序列化支持

### 步骤 3：实现生成器

**新建文件：`lib/services/generation/hyper_generator.dart`**

```dart
class HyperGenerator implements IGameGenerator {
  @override
  GameType get supportedGameType => GameType.hyper;

  @override
  Future<GenerationResult> generate({
    required Difficulty difficulty,
    required int size,
    ...
  }) async {
    // 1. 生成完整解（使用 BitSolver 或回溯）
    // 2. 挖空（使用 DiggingAlgorithm）
    // 3. 返回 GenerationResult(puzzle: ..., solution: ...)
  }
}
```

### 步骤 4：注册工厂和服务

**修改文件：`lib/services/game_factory.dart`**

1. `createGameService()` 的 switch 中添加 `case GameType.hyper`
2. `createGameGenerator()` 的 switch 中添加 `case GameType.hyper`
3. `getLocalizedGameName()` 中添加 hyper 的名称映射

**修改文件：`lib/services/generation/index.dart`**

- 添加 `export 'hyper_generator.dart';`

**修改文件：`lib/services/generation/puzzle_generator.dart`**（如需模板）

- 在模板加载逻辑中添加对应分支

### 步骤 5：序列化支持

**修改文件：`lib/models/generation_contracts.dart`**

```dart
// GenerationResult.fromJson() 的 switch 中添加：
case 'HyperBoard':
  return HyperBoard.fromJson(json['board'] as Map<String, dynamic>);
```

### 步骤 6：路由和 UI 注册

**修改文件：`lib/main.dart`**

1. `_GameScreenWrapper.build()` 的 switch 中添加 `case GameType.hyper`
2. `_createFinishScreen()` 的 switch 中添加 `case 'hyper'`
3. 如需自定义游戏路由，添加对应路由

**修改文件：`lib/views/home_page.dart`**

1. `_gameTypeStyles` 添加 `GameType.hyper` 的颜色和图标
2. 游戏类型描述映射添加 hyper 条目

**修改文件：`lib/views/components/boards/game_board_widget.dart`**（如有特殊绘制）

- 在 `_UnifiedBoardPainter` 中添加对应的绘制逻辑

### 步骤 7：配置文件

**修改文件：`assets/config/game_types.json`**

- 添加 hyper 游戏类型的完整 JSON 配置块

**修改文件：`assets/config/difficulty_config.json`**

- 每个难度级别的 `gameTypeConfigs` 中添加 hyper 的参数

### 步骤 8：国际化

**新建文件：**
- `assets/l10n/game_hyper_en.arb`（英文）
- `assets/l10n/game_hyper_zh.arb`（中文）

---

## 五、修改文件清单（快速检查表）

| 必要性 | 文件路径                                          | 修改内容                                     |
|--------|--------------------------------------------------|----------------------------------------------|
| 必修   | `lib/models/game_type.dart`                      | enum + ConfigFactory 添加 hyper              |
| 必修   | `lib/models/board.dart`                          | 添加 HyperBoard 子类                         |
| 必修   | `lib/services/game_factory.dart`                 | createGameService + createGameGenerator      |
| 必修   | `lib/services/generation/index.dart`             | export hyper_generator                       |
| 必修   | `lib/models/generation_contracts.dart`           | fromJson 添加 HyperBoard case                |
| 必修   | `lib/main.dart`                                  | 路由 + ViewModel + FinishScreen              |
| 必修   | `lib/views/home_page.dart`                       | 颜色 + 图标 + 描述                           |
| 必修   | `assets/config/game_types.json`                  | hyper 配置块                                 |
| 新建   | `lib/services/generation/hyper_generator.dart`   | 实现 IGameGenerator                          |
| 新建   | `assets/l10n/game_hyper_*.arb`                   | 国际化资源                                   |
| 可选   | `lib/services/game_config.dart`                  | 默认配置、图标映射                           |
| 可选   | `lib/services/game_validator.dart`               | 特殊验证规则（如有）                         |
| 可选   | `lib/views/components/boards/game_board_widget.dart` | 特殊绘制逻辑（如有）                        |
| 可选   | `assets/config/difficulty_config.json`           | 难度参数配置                                 |

---

## 六、注意事项

1. **Isolate 兼容**：生成器在 Isolate 中运行，新类型的所有依赖必须可序列化。`GenerationResult.toJson()/fromJson()` 必须支持新的 Board 子类。

2. **isFixed 管理**：生成过程中所有格子的 `isFixed` 必须保持 `false`，只在最终返回前统一标记有数字的格子为 `isFixed=true`。

3. **regions 是验证基础**：`GameValidator` 完全依赖 `Board.regions` 做区域唯一性验证，新类型的 `createRegions()` 必须正确创建所有约束区域。

4. **DiggingConfig 参数**：挖空算法用 `config.maxFilledCells` 作为目标填充数，必须确保该值小于子盘的实际填充数，否则挖空不会执行。

5. **GameType 的 switch 分支**分布在 8+ 个文件中，添加新类型时需逐一检查。建议全局搜索 `GameType` 确保不遗漏。

6. **响应式布局**：首页使用 `PageView` + `LayoutBuilder` 实现自适应，横屏 3 列（3×2），竖屏 2 列（2×3）。新游戏类型会自动出现在网格中。

---

## 七、项目文件索引

### Models 层

| 文件                    | 主要类                                                                 | 职责                           |
|-------------------------|------------------------------------------------------------------------|--------------------------------|
| `board.dart`            | Board, StandardBoard, DiagonalBoard, WindowBoard, JigsawBoard, KillerBoard, SamuraiBoard | 棋盘抽象基类及所有子类         |
| `cell.dart`             | Cell                                                                   | 单元格模型                     |
| `region.dart`           | RegionType, Region, RegionCollectionUtils                              | 区域模型与工具                 |
| `game_type.dart`        | GameType, GameTypeConfig, GameTypeConfigFactory                        | 游戏类型枚举与配置             |
| `game_state.dart`       | GameState<B>                                                           | 游戏整体状态                   |
| `difficulty.dart`       | Difficulty, DifficultyConfig                                           | 难度等级定义                   |
| `generation_contracts.dart` | IGameGenerator, GenerationResult, DiggingConfig                   | 生成器接口与契约               |
| `strategy.dart`         | StrategyType, StrategyInfo                                             | 解题策略元数据                 |
| `killer_cage.dart`      | KillerCage                                                             | 杀手数独笼子模型               |
| `game_stats.dart`       | GameStats                                                              | 游戏统计数据                   |
| `*_constants.dart`      | *Constants                                                             | 各游戏类型常量                 |

### Services 层

| 文件                        | 主要类                  | 职责                               |
|-----------------------------|-------------------------|------------------------------------|
| `game_service.dart`         | GameService<B>          | 游戏状态管理、用户操作、生成协调    |
| `game_factory.dart`         | GameFactory             | 创建 GameService 和 Generator      |
| `game_config.dart`          | GameConfig              | JSON 配置加载                      |
| `game_validator.dart`       | GameValidator           | 棋盘验证                           |
| `game_logic.dart`           | GameLogic               | 游戏逻辑（显示答案等）             |
| `game_storage_service.dart` | GameStorageService, SavedGameInfo | 游戏持久化                     |
| `audio_manager.dart`        | AudioManager            | 音频播放管理                       |
| `app_settings.dart`         | AppSettings             | 应用设置管理                       |
| `history_manager.dart`      | HistoryManager          | 撤销/重做历史                      |

### Generation 子模块

| 文件                          | 主要类                     | 职责                           |
|-------------------------------|----------------------------|--------------------------------|
| `puzzle_generator.dart`       | PuzzleGenerator            | 生成门面（模板加载 + Isolate 调度） |
| `game_generator.dart`         | GameGenerator              | 生成器注册分发                 |
| `digging_algorithm.dart`      | DiggingAlgorithm, SmartRandomDiggingAlgorithm | 挖空算法                 |
| `isolate_game_generator.dart` | IsolateGameGenerator       | Isolate 生成执行               |
| `message_protocol.dart`       | IsolateMessage             | Isolate 通信协议               |
| `template_manager.dart`       | TemplateManager            | 模板加载管理                   |
| `*_generator.dart`            | *Generator                 | 各类型专用生成器               |

### Solving 子模块

| 文件                          | 主要类                     | 职责                           |
|-------------------------------|----------------------------|--------------------------------|
| `strategy_engine.dart`        | StrategyService, StrategyRegistry | 策略注册与执行                 |
| `candidate_calculator.dart`   | CandidateCalculator, BoardContext | 候选数计算                     |
| `solvers/bit_solver.dart`     | BitSolver                  | 位掩码解计数                   |
| `solvers/dlx_solver.dart`     | DLXSudokuSolver            | DLX 求解器                     |
| `strategies/solving_strategies.dart` | 9 种策略类             | 人类解题策略                   |

### Views 层

| 文件                                   | 主要类                  | 职责                               |
|----------------------------------------|-------------------------|------------------------------------|
| `home_page.dart`                       | HomeScreen              | 首页（游戏类型 + 难度选择）         |
| `game_page.dart`                       | GameScreen<B>           | 游戏页面                           |
| `completion_page.dart`                 | FinishScreen            | 完成页面                           |
| `custom_game_page.dart`                | CustomGameScreen        | 自定义游戏页面                     |
| `settings_page.dart`                   | SettingsScreen          | 设置页面                           |
| `statistics_page.dart`                 | GameStatisticsScreen    | 统计页面                           |
| `components/boards/game_board_widget.dart` | UnifiedBoardWidget    | 统一棋盘组件                       |
| `components/boards/samurai_board_widget.dart` | SamuraiBoardWidget | 武士棋盘组件                       |
| `components/function_keyboard.dart`    | FunctionKeyboard        | 功能键盘                           |
| `components/number_keyboard.dart`      | NumberKeyboard          | 数字键盘                           |
| `components/top_toolbar.dart`          | TopToolbar              | 顶部工具栏                         |
| `components/stats_bar.dart`            | StatsBar                | 状态栏                             |

---

## 八、快速开始

### 环境要求

- Flutter 3.0+ 
- Dart 3.0+ 
- Android Studio 或 VS Code

### 安装步骤

1. 克隆项目
   ```bash
   git clone https://github.com/TomnyJoo/sudoku_collection.git
   cd sudoku_collection
   ```

2. 安装依赖
   ```bash
   flutter pub get
   ```

3. 运行项目
   ```bash
   flutter run
   ```

---

## 九、游戏玩法

1. **选择游戏类型**：在主界面选择喜欢的数独类型
2. **选择难度**：根据自己的水平选择难度级别
3. **开始游戏**：点击开始按钮开始游戏
4. **填写数字**：通过屏幕键盘输入数字
5. **使用功能**：
   - 提示：获取解题提示
   - 撤销：撤销上一步操作
   - 清除：清除当前单元格
   - 笔记：使用笔记功能标记可能的数字

---

## 十、主要功能

- **多难度级别**：从简单到专家级别的难度设置
- **游戏统计**：记录游戏时间、完成率等统计数据
- **游戏保存**：自动保存游戏进度，支持继续游戏
- **主题切换**：支持浅色和深色主题
- **音效**：游戏过程中的音效反馈
- **提示系统**：提供解题提示
- **自定义游戏**：支持创建自定义数独游戏
- **多语言支持**：支持中英文界面

---

## 十一、特色功能

### 智能生成算法
- 使用并行处理技术生成高质量的数独谜题
- 确保每个谜题都有唯一解
- 根据难度级别调整生成策略

### 游戏统计系统
- 记录每个游戏类型的完成时间
- 计算平均解题时间
- 跟踪游戏完成率

### 响应式设计
- 适配手机、平板等不同设备
- 自适应屏幕方向
- 优化触摸交互体验

---

## 十二、开发指南

### 添加新的数独类型

1. 在 `games/` 目录下创建新的游戏类型文件夹
2. 实现相应的模型、视图和服务
3. 在主界面添加新游戏类型的入口

### 自定义主题

1. 修改 `common/theme/app_colors.dart` 中的颜色定义
2. 在 `common/theme/app_text_styles.dart` 中调整文本样式
3. 通过设置界面切换主题

### 扩展方法使用

本项目使用了Flutter的扩展方法（Extension Methods）来简化本地化资源的访问，同时也提供了一套完整的机制来支持添加新的游戏类型。

#### 可用的扩展方法：

1. **BuildContext扩展**：
   - `context.appLocalizations`：获取通用本地化资源
   - `context.gameLocalizations`：获取游戏特定本地化资源
   - `context.localizations`：向后兼容，获取通用本地化资源
   - `context.currentLocaleCode`：获取当前语言代码

2. **使用示例**：
   ```dart
   // 获取通用本地化资源
   final appLocalizations = context.appLocalizations;
   String appName = appLocalizations.appName;
   
   // 获取游戏特定本地化资源
   final gameLocalizations = context.gameLocalizations;
   String gameTypeName = gameLocalizations.gameTypeStandardName;
   
   // 获取当前语言代码
   String localeCode = context.currentLocaleCode;
   ```

3. **LocalizationUtils类**：
   - `LocalizationUtils.app(context)`：获取通用本地化资源
   - `LocalizationUtils.game(context)`：获取游戏特定本地化资源
   - `LocalizationUtils.of(context)`：向后兼容，获取通用本地化资源
   - `LocalizationUtils.getCurrentLocaleCode(context)`：获取当前语言代码
   - `LocalizationUtils.supportedLocales`：获取支持的语言列表
   - `LocalizationUtils.localizationDelegates`：获取本地化代理列表

#### 添加新游戏类型时的操作步骤：

1. **创建游戏本地化文件**：
   - 在 `lib/common/l10n/` 目录下创建新游戏类型的本地化文件，例如：
     - `game_newgame_en.arb`：英文本地化文件
     - `game_newgame_zh.arb`：中文本地化文件
   - 确保文件中包含必要的本地化键，如游戏名称、描述和规则

2. **更新GameLocalizations类**：
   - 在 `lib/common/l10n/game_localizations.dart` 文件中，在 `_loadGameLocalizations` 方法中添加新游戏类型的本地化文件路径
   - 在 `GameLocalizations` 类中添加对应的getter方法，例如：
     ```dart
     String get gameTypeNewGameName => getString('gameTypeNewGameName') ?? 'New Game';
     String get gameTypeNewGameDescription => getString('gameTypeNewGameDescription') ?? 'New game description';
     String get gameTypeNewGameRules => getString('gameTypeNewGameRules') ?? 'New game rules';
     ```

3. **更新GameFactory类**：
   - 在 `lib/core/services/game_factory.dart` 文件中，在 `getGameNameLocalizationKey` 方法中添加新游戏类型的本地化键映射
   - 确保 `createGameGenerator` 方法能够处理新的游戏类型

4. **更新主界面**：
   - 在 `lib/common/home/home_screen.dart` 文件中，在游戏类型列表中添加新游戏类型
   - 使用 `LocalizationUtils.game(context)` 或 `context.gameLocalizations` 来获取新游戏类型的本地化名称和描述

5. **更新游戏配置**：
   - 在 `lib/core/services/game_config.dart` 文件中，添加新游戏类型的配置信息

通过以上步骤，您可以轻松地添加新的游戏类型，并且系统会自动处理本地化资源的加载和访问。

这些扩展方法和工具类使得本地化资源的访问更加简洁和直观，提高了代码的可读性和可维护性。

---

## 十三、贡献

欢迎提交Issue和Pull Request来改进这个项目！

---

## 十四、许可证

MIT License

---

## 十五、更新日志

### v1.2.2
- 修复音效设置问题：应用启动时未将设置的音效开关同步到音频管理器，导致音效关闭后重启应用仍播放开始音效
- 修复完成页点击"新游戏"卡死问题：加载对话框使用 await 导致死锁（对话框永远无法关闭）；同时导航未携带新游戏状态，新页面因无参数且无存档而显示空白棋盘
- 修复存在错误单元格时仍判定游戏完成的问题：完成判断增加错误单元格检查
- 修复错误计数恒为 0 的问题：recordMistake 从未被调用，现填入错误数字时正确累加错误数（状态栏错误计数同步生效）
- 修复自动候选数模式下，通过提示按钮填入数字后未重新计算候选数的问题

### v1.2.1
- 修复历史记录管理问题：当历史记录超过50条时，撤销操作会错误地撤销多步
- 优化历史记录管理逻辑：从头部移除命令时，将这些命令的效果正确合并到初始棋盘状态中
- 核心修复：在 HistoryManager.addCommand 方法中，正确处理超过最大历史记录限制的情况，确保 initialBoard 与保留的命令列表保持同步

### v1.2.0
- 系统架构全面重构，更好适配配置式、模块化管理
- 优化首页，增强用户体验
- 优化提高代码质量

### v1.1.2
- 修复优化难度控制系统，使用统一的难度控制策略
- 整合最佳记录与游戏统计系统，优化完善统计功能
- 优化提高代码质量

### v1.1.1
- 修复最佳记录管理问题
- 修复viewmodel单例模式问题，改为随页面变化而销毁
- 优化横屏模式下布局

### v1.1.0
- 配置化、模块化的整体架构调整，便于扩展和维护
- 本地化调整为手动管理，支持同语言多个arb文件
- 统计功能重构及增强
- 代码优化，提高性能和可维护性

### v1.0.6
- 优化提示服务，直接填入答案
- 清理无用代码
- 优化代码组织结构，提高可维护性

### v1.0.5
- 修复武士数独游戏完成后出现红屏错误
- 统一所有游戏完成页面的实现方式和页面导航方式
- 修正杀手数独用时计算错误问题，统一所有游戏的计时方式
- 优化游戏完成页面显示逻辑
- 优化武士数独候选数计算性能,采用局部计算

### v1.0.4
- 进一步系统化修复候选数计算问题（复杂工程）

### v1.0.3
- 修复杀手数独游戏完成检查逻辑的问题
- 清理杀手数独视图模型中不必要的方法重写
- 修复提示功能填入数字后自动计算候选数问题
- 修复清除单元格值后自动标记模式未重新计算候选数的问题

### v1.0.2
- 修复所有候选数计算问题
- 整合杀手数独候选数计算到通用逻辑

### v1.0.1
- 修复游戏完成后没有结束游戏的问题
- 修复提示服务对话框点击"应用"按钮后没有填入提示数字的问题
- 修复窗口数独窗口区域定义和使用逻辑不统一导致的系列问题

### v1.0.0
- 初始版本发布
- 支持6种数独类型
- 实现基本游戏功能
- 支持统计系统
- 支持主题切换
- 实现多语言支持