import 'dart:ffi';
import 'dart:typed_data';

import 'OutputStruct.dart';

/// The plugin's native library, opened once.
final DynamicLibrary nativeLib = DynamicLibrary.open('libyuv_to_png.so');

typedef _FreeBufferNative = Void Function(Pointer<Uint8> data);
typedef _FreeBuffer = void Function(Pointer<Uint8> data);

final _FreeBuffer _freePngBuffer =
    nativeLib.lookupFunction<_FreeBufferNative, _FreeBuffer>('freePngBuffer');

/// Copies the PNG bytes out of native memory and releases the native buffer.
Uint8List takePngBytes(OutputStruct output) {
  if (output.data == nullptr || output.length <= 0) {
    throw StateError('PNG conversion failed');
  }
  try {
    return Uint8List.fromList(output.data.asTypedList(output.length));
  } finally {
    _freePngBuffer(output.data);
  }
}
