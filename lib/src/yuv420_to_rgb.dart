import 'dart:ffi';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';

import 'RgbOutputStruct.dart';
import 'native_lib.dart';
import 'rgb_image.dart';

typedef _YuvToRgbNative = RgbOutputStruct Function(
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

typedef _YuvToRgb = RgbOutputStruct Function(
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

typedef _FreeRgbBufferNative = Void Function(Pointer<Uint8> data);
typedef _FreeRgbBuffer = void Function(Pointer<Uint8> data);

final _YuvToRgb _yuvToRgb =
    nativeLib.lookupFunction<_YuvToRgbNative, _YuvToRgb>('yuvToRgb');
final _FreeRgbBuffer _freeRgbBuffer = nativeLib
    .lookupFunction<_FreeRgbBufferNative, _FreeRgbBuffer>('freeRgbBuffer');

/// Converts a YUV420 [CameraImage] to a raw, rotated RGBA [RgbImage].
RgbImage yuv420ToRgb(CameraImage image,
    {CameraLensDirection lensDirection = CameraLensDirection.back}) {
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

    final RgbOutputStruct output = _yuvToRgb(
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

    if (output.data == nullptr || output.length <= 0) {
      throw StateError('YUV to RGB conversion failed');
    }
    try {
      // Copy out of native memory so the Dart object stays valid after the
      // native buffer is released.
      final Uint8List bytes =
          Uint8List.fromList(output.data.asTypedList(output.length));
      return RgbImage(bytes: bytes, width: output.width, height: output.height);
    } finally {
      _freeRgbBuffer(output.data);
    }
  } finally {
    calloc.free(yPointer);
    calloc.free(uPointer);
    calloc.free(vPointer);
  }
}
