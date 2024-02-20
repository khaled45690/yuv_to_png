
 import 'dart:ffi';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';

import 'OutputStruct.dart';
// Define the function signature in Dart.
typedef Nv21ToPngFunc = OutputStruct Function(Pointer<Uint8> ydata,
    Int32 yRowStride, Int32 width, Int32 height, Bool isFront);

// Define the function signature in Dart with matching C function's signature.
typedef Nv21ToPng = OutputStruct Function(
    Pointer<Uint8> ydata, int yRowStride, int width, int height, bool isFront);

Uint8List nv21ToPng(CameraImage image,
      {CameraLensDirection lensDirection = CameraLensDirection.back}) {
    // Convert the image planes to FFI pointers.
    // Load the dynamic library.
    final dylib = DynamicLibrary.open('libyuv_to_png.so');

    // Look up the function.
    final nv21ToPngPointer =
        dylib.lookupFunction<Nv21ToPngFunc, Nv21ToPng>('nv21ToPng');
    final yPlane = image.planes[0];

    Pointer<Uint8> yPointer = calloc<Uint8>(yPlane.bytes.length);
    Uint8List yPointerParser = yPointer.asTypedList(yPlane.bytes.length);
    yPointerParser.setAll(0, yPlane.bytes);
    // Call the C++ function.
    OutputStruct outputData = nv21ToPngPointer(yPointer, yPlane.bytesPerRow,
        image.width, image.height, lensDirection == CameraLensDirection.front);
    // Don't forget to free the memory when you're done!
    calloc.free(yPointer);
    dylib.close();
    return outputData.data.asTypedList(outputData.length);
  }