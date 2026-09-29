# Photo import fix — 1.0.2+3

Reported: Samsung A55 closes after gallery selection in release APK.

Changes: importing no longer invokes native ONNX inference automatically; optional background-removal button remains available. Gallery requests are guarded against duplicate taps; saving is disabled during selection. Picker dimensions are capped at 1600px and preview decode width at 800px. Release ProGuard config preserves ai.onnxruntime classes and members as required by ONNX JNI.

Cause is not confirmed without device logcat. R8 mapping in the previous release renamed ONNX members and the app did not include the documented keep rule.

Build: flutter pub get, then flutter build apk --release. Install updated APK over the existing app with the same signing key. Verify on A55: select photo and save original; then add a second photo and explicitly remove background; save cutout and reopen wardrobe; repeat with a large camera photo and cancel the gallery once. If the process still exits, capture adb logcat -b crash -d immediately afterwards. Do not claim the native crash fixed until device validation passes.
