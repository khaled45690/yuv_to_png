# yuv_to_png

A high-performance Flutter plugin for converting YUV camera image data to PNG format, optimized for Android applications.

## Overview

This plugin provides efficient YUV to PNG conversion with minimal dependencies and optimized performance. Perfect for processing camera frames in Flutter applications.

**Key Features:**

- ✅ Zero OpenCV dependency - smaller APK size (~ 24 mb saved per ABI)
- ✅ Fast conversion using libyuv library
- ✅ Automatic camera orientation handling (front/back)
- ✅ Support for YUV420 and NV21 formats
- ✅ Built-in rotation and mirroring for camera images
- ✅ Performance tracking with timing metrics

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  yuv_to_png: ^1.0.1
```

## Usage

### Basic Usage

```dart
import 'package:yuv_to_png/yuv_to_png.dart';
import 'package:camera/camera.dart';

// Convert camera image to PNG
Uint8List png = YuvToPng.yuvToPng(
  cameraImage,
  lensDirection: cameraController.description.lensDirection,
);

// Display the image
Image.memory(png)
```

if there is an error you can use the next function to check if
the image data is corrupted or not

```dart
        await precacheImage(Image.memory(imagedata).image, context,
        onError: (exception, stackTrace) {
      print('Failed to load image: $exception');
      imageRendered = false;
    });

```

if image data is corrupted you could simply use recurssion untill
we get correct image data

The PNG data can then be used to display the image in Flutter using `Image.memory()` or as shown in the example application.

## Optional

### Error Handling

```dart
try {
  Uint8List png = YuvToPng.yuvToPng(cameraImage, lensDirection: lensDirection);

  // Verify image data is valid
  await precacheImage(
    Image.memory(png).image,
    context,
    onError: (exception, stackTrace) {
      print('Failed to load image: $exception');
    }
  );
} catch (e) {
  print('Conversion error: $e');
}
```

## Supported Formats

- **YUV420** (planar format with separate Y, U, V planes)
- **NV21** (semi-planar format with interleaved UV)

Both formats are commonly used by Android camera APIs.

## Performance

Typical conversion times on modern Android devices:

- YUV → PNG: ~80-100ms (720p image)
- Includes: YUV conversion, rotation, mirroring, and PNG encoding

## Technical Details

### Architecture

- **YUV Conversion:** libyuv library (fast, optimized)
- **PNG Encoding:** stb_image_write.h (zero dependencies)
- **Image Processing:** libyuv for rotation and mirroring
- **Platform:** Android only (API 24+)

### Conversion Pipeline

1. YUV → RGBA (using libyuv)
2. Mirror (front camera only)
3. Rotate 90° clockwise (or 270° for front camera)
4. RGBA → PNG encoding

## Important Notes

⚠️ **Camera Orientation:** The `lensDirection` parameter is crucial for correct image orientation. Always pass the correct camera lens direction to ensure proper rotation and mirroring.

⚠️ **Android Only:** This plugin currently supports Android only, as YUV camera formats are primarily used on Android devices.

⚠️ **First Run:** When running the example app for the first time, use `flutter run` (debug mode). Running `flutter run --release` on the first build may fail. After the initial successful debug build, release mode will work properly.

## Roadmap

Future features under consideration:

- [ ] upon request methods or improvements

## Contact

For questions or support, connect with me on:

<a href="https://www.linkedin.com/in/khaled-saad-3b94b817b/">
  <img src="https://raw.githubusercontent.com/edent/SuperTinyIcons/master/images/svg/linkedin.svg" width="20" height="20"> LinkedIn
</a>

## License

MIT

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history and updates.
