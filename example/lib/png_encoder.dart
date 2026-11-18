import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

/// Minimal pure-Dart PNG encoder for tightly packed RGBA8888 pixels.
///
/// This is what the "RGB -> PNG (Dart)" pipeline uses to turn the raw output
/// of `YuvToPng.yuvToRgb` into a PNG without going through the native PNG
/// encoder. [level] is the zlib level (1 = fastest, 9 = smallest).
Uint8List encodePngRgba(
  Uint8List rgba,
  int width,
  int height, {
  int level = 1,
}) {
  final int stride = width * 4;
  if (width <= 0 || height <= 0 || rgba.length != stride * height) {
    throw ArgumentError(
      'Expected ${stride * height} bytes for ${width}x$height RGBA, '
      'got ${rgba.length}',
    );
  }

  // Every scanline is prefixed with a filter-type byte (0 = none).
  final Uint8List raw = Uint8List((stride + 1) * height);
  for (int y = 0; y < height; y++) {
    final int dst = y * (stride + 1);
    raw[dst] = 0;
    raw.setRange(dst + 1, dst + 1 + stride, rgba, y * stride);
  }
  final Uint8List idat = Uint8List.fromList(
    ZLibCodec(level: level).encode(raw),
  );

  final BytesBuilder out = BytesBuilder(copy: false)..add(_signature);

  final ByteData ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 6) // colour type: RGBA
    ..setUint8(10, 0) // compression
    ..setUint8(11, 0) // filter method
    ..setUint8(12, 0); // no interlace
  _writeChunk(out, 'IHDR', ihdr.buffer.asUint8List());
  _writeChunk(out, 'IDAT', idat);
  _writeChunk(out, 'IEND', Uint8List(0));
  return out.takeBytes();
}

final Uint8List _signature = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
]);

void _writeChunk(BytesBuilder out, String type, Uint8List data) {
  final Uint8List typeBytes = Uint8List.fromList(type.codeUnits);
  final ByteData length = ByteData(4)..setUint32(0, data.length);
  out.add(length.buffer.asUint8List());
  out.add(typeBytes);
  out.add(data);
  int crc = _crc32(typeBytes, 0xFFFFFFFF);
  crc = _crc32(data, crc) ^ 0xFFFFFFFF;
  final ByteData crcBytes = ByteData(4)..setUint32(0, crc);
  out.add(crcBytes.buffer.asUint8List());
}

final Uint32List _crcTable = () {
  final Uint32List table = Uint32List(256);
  for (int n = 0; n < 256; n++) {
    int c = n;
    for (int k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}();

int _crc32(Uint8List bytes, int crc) {
  for (final int b in bytes) {
    crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >> 8);
  }
  return crc;
}
