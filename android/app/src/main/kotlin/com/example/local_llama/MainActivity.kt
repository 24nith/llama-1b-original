package com.example.local_llama

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val CHANNEL = "local_llama/inference"

		init {
			System.loadLibrary("local-llama")
		}
	}

	private external fun generateNative(modelPath: String, prompt: String): String

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method != "generate") {
				result.notImplemented()
				return@setMethodCallHandler
			}
			val modelPath = call.argument<String>("modelPath")
			val prompt = call.argument<String>("prompt")
			if (modelPath.isNullOrBlank() || prompt.isNullOrBlank()) {
				result.error("INVALID_ARGUMENT", "A model path and prompt are required.", null)
				return@setMethodCallHandler
			}
			Thread {
				try {
					result.success(generateNative(modelPath, prompt))
				} catch (error: Exception) {
					result.error("INFERENCE_FAILED", error.message, null)
				}
			}.start()
		}
	}
}
