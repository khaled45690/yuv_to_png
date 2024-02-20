// Define the struct in Dart
import 'dart:ffi';

// Define the struct in Dart
final class OutputStruct extends Struct {
  external Pointer<Uint8> data;

  @Int32()
  external int length;
}