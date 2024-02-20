import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'src/nv21_to_png.dart';
import 'src/yuv420_to_png.dart';

class YuvToPng {
  static Uint8List yuvToPng(CameraImage image,
      {CameraLensDirection lensDirection = CameraLensDirection.back}) {
    if (image.format.group == ImageFormatGroup.yuv420)
      return yuv420ToPng(image, lensDirection: lensDirection);
    if (image.format.group == ImageFormatGroup.nv21)
      return nv21ToPng(image, lensDirection: lensDirection);

    throw "the only supported formates is yuv420 and nv21";
  }
}
