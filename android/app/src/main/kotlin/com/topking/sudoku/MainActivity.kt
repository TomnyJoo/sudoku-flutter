package com.topking.sudoku

import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val INSETS_CHANNEL = "com.topking.sudoku/system_insets"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSETS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getGestureInsets" -> result.success(readGestureInsets())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 通过 WindowInsetsCompat 读取系统手势区域，
     * 包含左右边缘的返回手势区与底部手势导航区，返回单位为 dp。
     */
    private fun readGestureInsets(): Map<String, Double> {
        val decorView = window.decorView
        val density = resources.displayMetrics.density
        val rootInsets = ViewCompat.getRootWindowInsets(decorView)
        if (rootInsets == null) {
            // 视图尚未附加到窗口时主动请求一次 insets 分发
            ViewCompat.requestApplyInsets(decorView)
            return mapOf("left" to 0.0, "top" to 0.0, "right" to 0.0, "bottom" to 0.0)
        }

        val gestures = rootInsets.getInsets(WindowInsetsCompat.Type.systemGestures())
        val mandatory = rootInsets.getInsets(WindowInsetsCompat.Type.mandatorySystemGestures())

        fun toDp(px: Int): Double = px / density.toDouble()

        return mapOf(
            "left" to toDp(maxOf(gestures.left, mandatory.left)),
            "top" to toDp(maxOf(gestures.top, mandatory.top)),
            "right" to toDp(maxOf(gestures.right, mandatory.right)),
            "bottom" to toDp(maxOf(gestures.bottom, mandatory.bottom)),
        )
    }
}
