import 'dart:ffi';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';
import 'OutputStruct.dart';
import 'native_lib.dart';

// Define the function signature in Dart.
typedef YuvToPngFunc = OutputStruct Function(
    Pointer<Uint8> ydata,
    Int32 yRowStride,
    Pointer<Uint8> udata,
    Int32 uRowStride,
    Int32 uPixelStride,
    Pointer<Uint8> vdata,
    Int32 vRowStride,
    Int32 width,
    Int32 height,
    Bool isFront);

// Define the function signature in Dart with matching C function's signature.
typedef YuvToPngFun = OutputStruct Function(
    Pointer<Uint8> ydata,
    int yRowStride,
    Pointer<Uint8> udata,
    int uRowStride,
    int uPixelStride,
    Pointer<Uint8> vdata,
    int vRowStride,
    int width,
    int height,
    bool isFront);

Uint8List yuv420ToPng(CameraImage image,
    {CameraLensDirection lensDirection = CameraLensDirection.back}) {
  final yuvToPng =
      nativeLib.lookupFunction<YuvToPngFunc, YuvToPngFun>('yuvToPng');
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];
  final Pointer<Uint8> yPointer = calloc<Uint8>(yPlane.bytes.length);
  final Pointer<Uint8> uPointer = calloc<Uint8>(uPlane.bytes.length);
  final Pointer<Uint8> vPointer = calloc<Uint8>(vPlane.bytes.length);
  try {
    yPointer.asTypedList(yPlane.bytes.length).setAll(0, yPlane.bytes);
    uPointer.asTypedList(uPlane.bytes.length).setAll(0, uPlane.bytes);
    vPointer.asTypedList(vPlane.bytes.length).setAll(0, vPlane.bytes);

    final OutputStruct output = yuvToPng(
        yPointer,
        yPlane.bytesPerRow,
        uPointer,
        uPlane.bytesPerRow,
        uPlane.bytesPerPixel ?? 1,
        vPointer,
        vPlane.bytesPerRow,
        image.width,
        image.height,
        lensDirection == CameraLensDirection.front);
    return takePngBytes(output);
  } finally {
    calloc.free(yPointer);
    calloc.free(uPointer);
    calloc.free(vPointer);
  }
}
