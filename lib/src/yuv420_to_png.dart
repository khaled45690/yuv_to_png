import 'dart:ffi';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';
import 'OutputStruct.dart';
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
  // Convert the image planes to FFI pointers.
  // Load the dynamic library.
  final dylib = DynamicLibrary.open('libyuv_to_png.so');

  // Look up the function.
  final yuvToPngPointer =
      dylib.lookupFunction<YuvToPngFunc, YuvToPngFun>('yuvToPng');
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];
  Pointer<Uint8> yPointer = calloc<Uint8>(yPlane.bytes.length);
  Pointer<Uint8> uPointer = calloc<Uint8>(uPlane.bytes.length);
  Pointer<Uint8> vPointer = calloc<Uint8>(vPlane.bytes.length);
  Uint8List yPointerParser = yPointer.asTypedList(yPlane.bytes.length);
  Uint8List uPointerParser = uPointer.asTypedList(yPlane.bytes.length);
  Uint8List vPointerParser = vPointer.asTypedList(yPlane.bytes.length);

  yPointerParser.setAll(0, yPlane.bytes);
  uPointerParser.setAll(0, uPlane.bytes);
  vPointerParser.setAll(0, vPlane.bytes);

  // Call the C++ function.
  OutputStruct outputData = yuvToPngPointer(
      yPointer,
      yPlane.bytesPerRow,
      uPointer,
      uPlane.bytesPerRow,
      uPlane.bytesPerPixel!,
      vPointer,
      vPlane.bytesPerRow,
      image.width,
      image.height,
      lensDirection == CameraLensDirection.front);

  // TODO: Use outputData here.
  // Don't forget to free the memory when you're done!
  calloc.free(yPointer);
  calloc.free(uPointer);
  calloc.free(vPointer);
  dylib.close();
  return outputData.data.asTypedList(outputData.length);
}