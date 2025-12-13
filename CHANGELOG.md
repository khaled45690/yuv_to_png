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
