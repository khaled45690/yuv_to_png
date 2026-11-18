import 'dart:ffi';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';

import 'OutputStruct.dart';
import 'native_lib.dart';

// Define the function signature in Dart.
typedef Nv21ToPngFunc = OutputStruct Function(Pointer<Uint8> ydata,
    Int32 yRowStride, Int32 width, Int32 height, Bool isFront);

// Define the function signature in Dart with matching C function's signature.
typedef Nv21ToPng = OutputStruct Function(
    Pointer<Uint8> ydata, int yRowStride, int width, int height, bool isFront);

Uint8List nv21ToPng(CameraImage image,
    {CameraLensDirection lensDirection = CameraLensDirection.back}) {
  final nv21ToPngFn =
      nativeLib.lookupFunction<Nv21ToPngFunc, Nv21ToPng>('nv21ToPng');
  final yPlane = image.planes[0];

  final Pointer<Uint8> yPointer = calloc<Uint8>(yPlane.bytes.length);
  try {
    yPointer.asTypedList(yPlane.bytes.length).setAll(0, yPlane.bytes);
    final OutputStruct output = nv21ToPngFn(yPointer, yPlane.bytesPerRow,
        image.width, image.height, lensDirection == CameraLensDirection.front);
    return takePngBytes(output);
  } finally {
    calloc.free(yPointer);
  }
}
