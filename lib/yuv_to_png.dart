import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'src/nv21_to_png.dart';
import 'src/rgb_image.dart';
import 'src/yuv420_to_png.dart';
import 'src/yuv420_to_rgb.dart';

export 'src/rgb_image.dart' show RgbImage;

class YuvToPng {
  static Uint8List yuvToPng(CameraImage image,
      {CameraLensDirection lensDirection = CameraLensDirection.back}) {
    if (image.format.group == ImageFormatGroup.yuv420)
      return yuv420ToPng(image, lensDirection: lensDirection);
    if (image.format.group == ImageFormatGroup.nv21)
      return nv21ToPng(image, lensDirection: lensDirection);

    throw "the only supported formates is yuv420 and nv21";
  }

  /// Converts a camera frame to raw RGBA pixels, skipping PNG encoding.
  ///
  /// The result is rotated to portrait (and mirrored for the front camera),
  /// exactly like [yuvToPng]. Only [ImageFormatGroup.yuv420] is supported.
  /// To draw it in Flutter use `ui.decodeImageFromPixels(rgb.bytes, rgb.width,
  /// rgb.height, ui.PixelFormat.rgba8888, callback)`.
  static RgbImage yuvToRgb(CameraImage image,
      {CameraLensDirection lensDirection = CameraLensDirection.back}) {
    if (image.format.group == ImageFormatGroup.yuv420)
      return yuv420ToRgb(image, lensDirection: lensDirection);

    throw "yuvToRgb only supports yuv420";
  }
}
