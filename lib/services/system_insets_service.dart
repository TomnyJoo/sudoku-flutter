import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 系统手势区域服务
///
/// 通过 Android 原生 `WindowInsetsCompat` 获取系统手势区域
/// （左右边缘返回手势区、底部手势导航区），
/// 用于让棋盘与键盘自动避开系统手势热区。
class SystemInsetsService {
  static const MethodChannel _channel = MethodChannel(
    'com.topking.sudoku/system_insets',
  );

  /// 系统左右边缘手势区域宽度（逻辑像素），取左右两侧较大值。
  ///
  /// 非 Android 平台或原生不可用时返回 0。
  static Future<double> getHorizontalGestureMargin() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 0;
    }
    try {
      final insets = await _channel.invokeMapMethod<String, double>(
        'getGestureInsets',
      );
      if (insets == null) return 0;
      return math.max(insets['left'] ?? 0, insets['right'] ?? 0);
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }
}
