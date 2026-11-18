import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:yuv_to_png_example/png_encoder.dart';

void main() {
  test('writes a well-formed PNG header', () {
    final Uint8List png = encodePngRgba(Uint8List(3 * 2 * 4), 3, 2);
    expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    final ByteData d = ByteData.sublistView(png);
    expect(d.getUint32(8), 13); // IHDR length
    expect(String.fromCharCodes(png.sublist(12, 16)), 'IHDR');
    expect(d.getUint32(16), 3); // width
    expect(d.getUint32(20), 2); // height
    expect(png[24], 8); // bit depth
    expect(png[25], 6); // RGBA
    expect(
      String.fromCharCodes(png.sublist(png.length - 8, png.length - 4)),
      'IEND',
    );
  });

  test('rejects a buffer of the wrong size', () {
    expect(() => encodePngRgba(Uint8List(10), 3, 2), throwsArgumentError);
  });

  testWidgets('round-trips pixels through the Flutter PNG decoder', (
    tester,
  ) async {
    // 2x2 opaque pixels (Flutter's decoder premultiplies alpha, so avoid
    // translucent ones in an exact comparison).
    final Uint8List rgba = Uint8List.fromList([
      255, 0, 0, 255, 0, 255, 0, 255, //
      0, 0, 255, 255, 10, 20, 30, 255,
    ]);
    await tester.runAsync(() async {
      final Uint8List png = encodePngRgba(rgba, 2, 2);
      final ui.Codec codec = await ui.instantiateImageCodec(png);
      final ui.Image image = (await codec.getNextFrame()).image;
      expect((image.width, image.height), (2, 2));
      final ByteData decoded = (await image.toByteData())!;
      expect(decoded.buffer.asUint8List(), rgba);
    });
  });
}
