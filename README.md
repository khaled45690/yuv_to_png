# yuv_to_png

A new Flutter plugin project that converts YUV image data to PNG image. 

## Overview

This package provides a Flutter plugin to convert YUV image data into PNG image format. It includes platform-specific implementation code for Android only as this from my knowledge happens only in Android systems . 

The plugin takes in CameraImage image data in both yuv240 and nv21 and returns a PNG image in uint8;ist . This allows you to process camera frames, video frames etc captured natively in YUV format and convert them to PNG that can be displayed in Flutter when needed.

## Usage

To use this plugin:

1. install and import the plugin
2. Call `YuvToPng.yuvToPng` method passing and parse the CameraImage variable
3. it will handle the conversion and identification of the image formate and returns a `Uint8List` containing PNG image data

For example:

```dart
    Uint8List png = YuvToPng.yuvToPng(cameraImage,
    lensDirection: lensDirection);
```

The PNG data can then be used to display the image in Flutter using `Image.memory()` or as shown in the example .

## Note

please note that lensDirection effect the image rotation correction which might effect the image orientation if neglected

## Getting Started

This project contains platform specific implementation for Android. To use this plugin:

1. Add this package as a dependency in pubspec.yaml
2. Import the package in Dart code
3. Follow the usage instructions above

For help getting started with Flutter development, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

