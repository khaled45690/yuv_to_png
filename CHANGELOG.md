## 1.2.0 - November 2026

### Highlights

- New **`YuvToPng.yuvToRgb`**: camera frame → raw RGBA pixels, no PNG round trip.
- Fixed a **use-after-free** that could corrupt PNG output.
- Builds with **Flutter 3.50** (Gradle 9, AGP 9, Kotlin 2.4, Java 17).

### Added

- **`YuvToPng.yuvToRgb`** - converts a YUV420 `CameraImage` straight to raw RGBA pixels
  (`RgbImage` with `bytes`, `width`, `height`), skipping PNG encoding and decoding.
  Same rotation / front-camera mirroring as `yuvToPng`. Draw it with
  `ui.decodeImageFromPixels(..., ui.PixelFormat.rgba8888, ...)`.
- Integration tests for `yuvToRgb` and the PNG paths using synthetic YUV frames.
- Example app redesigned ("YUV Lab"): dark full-bleed camera view, live FPS / convert time /
  output size / resolution, and a pipeline picker to compare **Native PNG**, **Raw RGB** and
  **RGB → PNG (Dart)** (native RGBA, PNG encoded by a pure-Dart encoder in an isolate).

### Fixed

- **Use-after-free in `yuvToPng` / `nv21ToPng`**: the native code returned a pointer into a
  `std::vector` that was destroyed on return, so PNG bytes could be corrupted (hence the old
  "retry if the image is corrupted" advice). The PNG is now copied into a `malloc`'d buffer,
  copied into Dart and freed (`freePngBuffer`). Failures now throw instead of returning garbage.
- U/V plane views were sized with the Y plane's length; they now use their own plane length.
- The native library is opened once instead of being opened and closed on every frame.

### Changed

- **Breaking:** a failed conversion now throws a `StateError` instead of returning corrupt bytes,
  so the old "retry until the image is valid" workaround is no longer needed.
- **Requires Flutter 3.50+ / Dart 3.14+** (the plugin's Gradle setup now targets Gradle 9 and AGP 9;
  older toolchains were not tested).

### Build

- Builds with Flutter 3.50: Gradle 9.5.0, AGP 9.3.1, Kotlin 2.4.20, Java 17 (example app and plugin).
- Plugin no longer pins CMake 4.1.0 (`cmake_minimum_required` lowered to 3.22; AGP picks the CMake version).
- Rebuilt the prebuilt `libconversion.so` (arm64-v8a, armeabi-v7a, x86_64) with NDK 29.
- `Conversion/buildAndroid.sh` no longer contains machine-specific paths.

## 1.0.1 - December 2025

### Major Changes

- **Removed OpenCV dependency** - Replaced with `stb_image_write.h` for PNG encoding

  - Significantly reduced APK size (~ 25MB saved per architecture)
  - Simpler build process with zero external dependencies for PNG encoding
  - Maintained same functionality with minimal performance impact

- **Migrated to libyuv for all image operations**
  - Replaced OpenCV flip/rotate with libyuv's `ARGBMirror` and `ARGBRotate`
  - Fixed critical crash issues with in-place rotation
  - Added proper ARGB to RGBA conversion for correct color output
  - Eliminated blue skin color bug in PNG output

### Architecture Changes

- **Improved CMake build system**

  - Added automatic library download with multiple mirror fallback
  - Enhanced error handling with clear warning messages
  - Added ELF binary verification for downloaded files
  - Graceful handling of missing libraries with user guidance

- **Front camera handling**
  - Fixed mirror/flip logic for front-facing camera
  - Added conditional rotation (270° for front, 90° for back camera)
  - Proper horizontal flip using `ARGBMirror`

### Dependencies

- **Removed:** OpenCV (libopencv_java4.so)
- **Added:** stb_image_write.h (single-header library, ~50-80 KB)
- **Retained:** libyuv (for YUV conversion and image manipulation)

### Technical Details

- Conversion pipeline: YUV → ARGB → Mirror/Rotate → RGBA → PNG
- Uses libyuv for: `Android420ToARGB`, `NV21ToARGB`, `ARGBMirror`, `ARGBRotate`, `ARGBToRGBA`
- PNG encoding via stb_image_write with memory callback for `std::vector<uint8_t>`
- Proper memory management with separate buffers for each transformation stage

## 0.0.2 - Initial Release

- Flutter plugin for YUV to PNG conversion
- Support for YUV420 and NV21 formats
- Camera image processing with rotation and flip
- Android-only implementation
- OpenCV-based image processing
