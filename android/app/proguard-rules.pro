# ONNX uses JNI lookups; preserve names and members in release builds.
# https://onnxruntime.ai/docs/build/android.html
-keep class ai.onnxruntime.** { *; }
