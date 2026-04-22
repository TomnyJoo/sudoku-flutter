/// 数独单元格具体类（表示数独棋盘中的单个单元格，包含位置、值、状态等信息）
class Cell {  /// 单元格颜色索引（用于标记不同区域或状态）

  /// 构造单元格模型
  const Cell({
    required this.row,
    required this.col,
    this.value,
    this.isFixed = false,
    this.isError = false,
    final Set<int>? candidates,
    this.isSelected = false,
    this.isHighlighted = false,
    this.colorIndex,
  }) : candidates = candidates ?? const <int>{};

  /// 从JSON创建单元格实例
  factory Cell.fromJson(final Map<String, dynamic> json) => Cell(
      row: json['row'] as int,
      col: json['col'] as int,
      value: json['value'] as int?,
      isFixed: json['isFixed'] as bool? ?? false,
      isError: json['isError'] as bool? ?? false,
      candidates: json['candidates'] != null 
          ? Set<int>.from((json['candidates'] as List).cast<int>()) 
          : null,
      isSelected: json['isSelected'] as bool? ?? false,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int?,
    );

  final int row;  /// 行索引（0-based）
  final int col;  /// 列索引（0-based） 
  final int? value;  /// 当前填入的数字（null表示未填）
  final bool isFixed;  /// 是否固定数字（游戏开始时存在的不可修改数字）
  final bool isError;  /// 是否数字冲突（违反数独规则） 
  final Set<int> candidates;  /// 候选数字集合（用于提示模式）
  final bool isSelected;  /// 是否被选中
  final bool isHighlighted;  /// 是否高亮显示（同行/同列/同区域高亮）
  final int? colorIndex;

  /// 生成新单元格副本，允许覆盖指定属性，返回新的单元格实例
  Cell copyWith({
    int? value,
    bool clearValue = false,
    bool? isFixed,
    bool? isError,
    Set<int>? candidates,
    bool? isSelected,
    bool? isHighlighted,
    int? colorIndex,
  }) => createInstance(
      row: row,
      col: col,
      value: clearValue ? null : (value ?? this.value),
      isFixed: isFixed ?? this.isFixed,
      isError: isError ?? this.isError,
      candidates: candidates ?? this.candidates,
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      colorIndex: colorIndex ?? this.colorIndex,
    );

  /// 创建单元格实例
  Cell createInstance({
    required int row,
    required int col,
    int? value,
    bool isFixed = false,
    bool isError = false,
    Set<int>? candidates,
    bool isSelected = false,
    bool isHighlighted = false,
    int? colorIndex,
  }) => Cell(
      row: row,
      col: col,
      value: value,
      isFixed: isFixed,
      isError: isError,
      candidates: candidates,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      colorIndex: colorIndex,
    );

  /// 转换为JSON格式，用于持久化存储，返回：包含单元格数据的Map
  Map<String, dynamic> toJson() => {
      'row': row,
      'col': col,
      'value': value,
      'isFixed': isFixed,
      'isError': isError,
      'candidates': candidates.toList(),
      'isSelected': isSelected,
      'isHighlighted': isHighlighted,
      'colorIndex': colorIndex,
    };

  /// 检查单元格是否为空（未填数字）
  bool get isEmpty => value == null;

  /// 检查单元格是否可编辑（非固定单元格）
  bool get isEditable => !isFixed;

  /// 重置单元格状态（清除错误、选中、高亮状态）
  Cell resetState() => copyWith(
      isError: false,
      isSelected: false,
      isHighlighted: false,
    );

  /// 清除单元格内容（保留固定状态）
  Cell clear() {
    if (isFixed) return this;
    return copyWith(
      clearValue: true,
      candidates: <int>{},
      isError: false,
    );
  }

  /// 添加候选数字
  Cell addCandidate(final int number) {
    if (number < 1 || number > 9) {
      final errorMsg = '候选数字必须在1-9范围内: $number';
      throw ArgumentError(errorMsg);
    }
    final newCandidates = Set<int>.from(candidates)..add(number);
    return copyWith(candidates: newCandidates);
  }

  /// 移除候选数字
  Cell removeCandidate(final int number) {
    final newCandidates = Set<int>.from(candidates)..remove(number);
    return copyWith(candidates: newCandidates);
  }

  /// 切换候选数字
  Cell toggleCandidate(final int number) {
    if (number < 1 || number > 9) {
      final errorMsg = '候选数字必须在1-9范围内: $number';
      throw ArgumentError(errorMsg);
    }
    final newCandidates = Set<int>.from(candidates);
    if (newCandidates.contains(number)) {
      newCandidates.remove(number);
    } else {
      newCandidates.add(number);
    }
    return copyWith(candidates: newCandidates);
  }

  /// 清除所有候选数字
  Cell clearCandidates() => copyWith(candidates: <int>{});

  /// 设置单元格值，并清除候选数字
  Cell setValue(final int? newValue) {
    if (newValue != null && (newValue < 1 || newValue > 9)) {
      final errorMsg = '数字值必须在1-9范围内: $newValue';
      throw ArgumentError(errorMsg);
    }
    return createInstance(
      row: row,
      col: col,
      value: newValue,
      isFixed: isFixed,
      candidates: <int>{},
      isSelected: isSelected,
      isHighlighted: isHighlighted,
      colorIndex: colorIndex,
    );
  }

  /// 检查单元格是否包含指定候选数字
  bool hasCandidate(final int number) => candidates.contains(number);

  /// 获取显示值（用于UI显示）
  String get displayValue => value?.toString() ?? '';

  /// 获取候选数字的字符串表示（用于UI显示）
  String getCandidatesDisplay({final String separator = ', '}) {
    if (candidates.isEmpty) return '';
    final sortedCandidates = candidates.toList()..sort();
    return sortedCandidates.join(separator);
  }

  /// 检查单元格是否等于另一个对象
  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    return other is Cell &&
        other.row == row &&
        other.col == col &&
        other.value == value &&
        other.isFixed == isFixed &&
        other.isError == isError &&
        other.isSelected == isSelected &&
        other.isHighlighted == isHighlighted &&
        other.colorIndex == colorIndex;
  }

  /// 获取哈希码，用于在集合中快速查找
  @override
  int get hashCode => Object.hash(
      row,
      col,
      value,
      isFixed,
      isError,
      isSelected,
      isHighlighted,
      colorIndex,
    );

  /// 获取用于调试的字符串表示（不依赖国际化），返回调试用的字符串表示
  String toDebugString() =>
     'Cell(row: $row, col: $col, value: $value, isFixed: $isFixed, '
        'isError: $isError, isSelected: $isSelected, isHighlighted: $isHighlighted, colorIndex: $colorIndex)';

  /// 获取用于显示的字符串表示（考虑国际化）
  String toDisplayString({final dynamic localizations}) {
    // 使用本地化字符串或默认值
    final emptyCellText = localizations != null ? _getLocalizedEmptyCellText(localizations) : '空';
    final fixedText = localizations != null ? _getLocalizedFixedText(localizations, isFixed) : (isFixed ? '固定' : '可编辑');
    final errorText = localizations != null ? _getLocalizedErrorText(localizations, isError) : (isError ? '错误' : '正确');
    final selectedText = localizations != null ? _getLocalizedSelectedText(localizations, isSelected) : (isSelected ? '选中' : '未选中');
    final highlightedText = localizations != null ? _getLocalizedHighlightedText(localizations, isHighlighted) : (isHighlighted ? '高亮' : '正常');
    
    final valueStr = value?.toString() ?? emptyCellText;
    
    return '单元格(${row + 1},${col + 1}): 值=$valueStr, $fixedText, $errorText, $selectedText, $highlightedText';
  }

  /// 获取本地化的空单元格文本
  String _getLocalizedEmptyCellText(final dynamic localizations) {
    // 尝试调用本地化方法，如果不存在则返回默认值
    try {
      if (localizations is Map && localizations.containsKey('emptyCell')) {
        return localizations['emptyCell'];
      }
      // 如果localizations是AppLocalizations实例，可以调用相应方法
      // 这里使用反射或动态调用，暂时返回默认值
    } catch (e) {
      // 忽略异常，返回默认值
    }
    return '空';
  }

  /// 获取本地化的固定状态文本
  String _getLocalizedFixedText(final dynamic localizations, final bool isFixed) {
    try {
      if (localizations is Map) {
        return isFixed ? (localizations['fixedCell'] ?? '固定') : (localizations['editableCell'] ?? '可编辑');
      }
    } catch (e) {
      // 忽略异常
    }
    return isFixed ? '固定' : '可编辑';
  }

  /// 获取本地化的错误状态文本
  String _getLocalizedErrorText(final dynamic localizations, final bool isError) {
    try {
      if (localizations is Map) {
        return isError ? (localizations['errorCell'] ?? '错误') : (localizations['correctCell'] ?? '正确');
      }
    } catch (e) {
      // 忽略异常
    }
    return isError ? '错误' : '正确';
  }

  /// 获取本地化的选中状态文本
  String _getLocalizedSelectedText(final dynamic localizations, final bool isSelected) {
    try {
      if (localizations is Map) {
        return isSelected ? (localizations['selectedCell'] ?? '选中') : (localizations['unselectedCell'] ?? '未选中');
      }
    } catch (e) {
      // 忽略异常
    }
    return isSelected ? '选中' : '未选中';
  }

  /// 获取本地化的高亮状态文本
  String _getLocalizedHighlightedText(final dynamic localizations, final bool isHighlighted) {
    try {
      if (localizations is Map) {
        return isHighlighted ? (localizations['highlightedCell'] ?? '高亮') : (localizations['normalCell'] ?? '正常');
      }
    } catch (e) {
      // 忽略异常
    }
    return isHighlighted ? '高亮' : '正常';
  }

  @override
  String toString() => toDebugString();
}
