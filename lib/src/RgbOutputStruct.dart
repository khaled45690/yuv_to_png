import 'dart:ffi';

/// Mirrors `OutputRgbImageStruct` in conversion.h.
final class RgbOutputStruct extends Struct {
  external Pointer<Uint8> data;

  @Int32()
  external int length;

  @Int32()
  external int width;

  @Int32()
  external int height;
}
