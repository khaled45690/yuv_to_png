// Integration test: runs on a device/emulator because it loads the plugin's
// native library through FFI.
//
//   flutter test integration_test/plugin_integration_test.dart -d <device>

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart'
    show CameraImageData, CameraImageFormat, CameraImagePlane;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:yuv_to_png/yuv_to_png.dart';
import 'package:yuv_to_png_example/png_encoder.dart';

/// Builds a 4x2 planar YUV420 frame. The left half is red and the right half
/// is blue, on both rows.
CameraImage _redBlueFrame() {
  const int width = 4;
  const int height = 2;
  // BT.601 limited range: red = (81, 90, 240), blue = (41, 240, 110).
  final y = Uint8List.fromList([81, 81, 41, 41, 81, 81, 41, 41]);
  final u = Uint8List.fromList([90, 240]);
  final v = Uint8List.fromList([240, 110]);
  return CameraImage.fromPlatformInterface(
    CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
      width: width,
      height: height,
      planes: [
        CameraImagePlane(
          bytes: y,
          bytesPerRow: width,
          bytesPerPixel: 1,
          width: width,
          height: height,
        ),
        CameraImagePlane(
          bytes: u,
          bytesPerRow: width ~/ 2,
          bytesPerPixel: 1,
          width: width ~/ 2,
          height: height ~/ 2,
        ),
        CameraImagePlane(
          bytes: v,
          bytesPerRow: width ~/ 2,
          bytesPerPixel: 1,
          width: width ~/ 2,
          height: height ~/ 2,
        ),
      ],
    ),
  );
}

/// Same picture as [_redBlueFrame] but as NV21 (Y plane followed by VU pairs).
CameraImage _redBlueNv21Frame() {
  const int width = 4;
  const int height = 2;
  final bytes = Uint8List.fromList([
    81, 81, 41, 41, 81, 81, 41, 41, // Y
    240, 90, 110, 240, // V,U for red then V,U for blue
  ]);
  return CameraImage.fromPlatformInterface(
    CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.nv21, raw: 17),
      width: width,
      height: height,
      planes: [
        CameraImagePlane(
          bytes: bytes,
          bytesPerRow: width,
          bytesPerPixel: 1,
          width: width,
          height: height,
        ),
      ],
    ),
  );
}

const List<int> _pngSignature = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
];

/// Decodes [png] and returns `[w, h, rgba bytes]`.
Future<(int, int, ByteData)> _decode(Uint8List png) async {
  expect(png.sublist(0, 8), _pngSignature);
  final ui.Codec codec = await ui.instantiateImageCodec(png);
  final ui.Image image = (await codec.getNextFrame()).image;
  final ByteData data = (await image.toByteData())!;
  return (image.width, image.height, data);
}

List<int> _px(ByteData d, int w, int x, int row) {
  final int i = (row * w + x) * 4;
  return [for (int k = 0; k < 4; k++) d.getUint8(i + k)];
}

/// Returns `[r, g, b, a]` of the pixel at ([x], [row]).
List<int> _pixel(RgbImage img, int x, int row) {
  final int i = (row * img.width + x) * RgbImage.bytesPerPixel;
  return img.bytes.sublist(i, i + 4);
}

bool _isRed(List<int> p) => p[0] > 200 && p[1] < 60 && p[2] < 60 && p[3] == 255;
bool _isBlue(List<int> p) =>
    p[2] > 200 && p[0] < 60 && p[1] < 60 && p[3] == 255;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('back camera: rotated 90 degrees clockwise, RGBA, no PNG', () {
    final RgbImage img = YuvToPng.yuvToRgb(_redBlueFrame());

    // 4x2 landscape frame becomes 2x4 portrait.
    expect(img.width, 2);
    expect(img.height, 4);
    expect(img.bytes.length, 2 * 4 * 4);
    // Not a PNG: no PNG signature at the start.
    expect(img.bytes.sublist(0, 4), isNot([0x89, 0x50, 0x4E, 0x47]));

    // Red (left half) ends up on top, blue at the bottom.
    for (int x = 0; x < 2; x++) {
      expect(
        _isRed(_pixel(img, x, 0)),
        isTrue,
        reason: 'row 0 ${_pixel(img, x, 0)}',
      );
      expect(
        _isRed(_pixel(img, x, 1)),
        isTrue,
        reason: 'row 1 ${_pixel(img, x, 1)}',
      );
      expect(
        _isBlue(_pixel(img, x, 2)),
        isTrue,
        reason: 'row 2 ${_pixel(img, x, 2)}',
      );
      expect(
        _isBlue(_pixel(img, x, 3)),
        isTrue,
        reason: 'row 3 ${_pixel(img, x, 3)}',
      );
    }
  });

  test('front camera: rotated 270 degrees (mirrored)', () {
    final RgbImage img = YuvToPng.yuvToRgb(
      _redBlueFrame(),
      lensDirection: CameraLensDirection.front,
    );

    expect(img.width, 2);
    expect(img.height, 4);
    // Mirrored relative to the back camera: blue on top, red at the bottom.
    for (int x = 0; x < 2; x++) {
      expect(
        _isBlue(_pixel(img, x, 0)),
        isTrue,
        reason: 'row 0 ${_pixel(img, x, 0)}',
      );
      expect(
        _isBlue(_pixel(img, x, 1)),
        isTrue,
        reason: 'row 1 ${_pixel(img, x, 1)}',
      );
      expect(
        _isRed(_pixel(img, x, 2)),
        isTrue,
        reason: 'row 2 ${_pixel(img, x, 2)}',
      );
      expect(
        _isRed(_pixel(img, x, 3)),
        isTrue,
        reason: 'row 3 ${_pixel(img, x, 3)}',
      );
    }
  });

  test(
    'repeated calls do not corrupt results (native buffer is freed/copied)',
    () {
      final RgbImage first = YuvToPng.yuvToRgb(_redBlueFrame());
      for (int i = 0; i < 200; i++) {
        YuvToPng.yuvToRgb(_redBlueFrame());
      }
      // `first` must still hold valid data after its native buffer was released.
      expect(_isRed(_pixel(first, 0, 0)), isTrue);
      expect(_isBlue(_pixel(first, 0, 3)), isTrue);
    },
  );

  for (final c in {
    'yuv420': _redBlueFrame,
    'nv21': _redBlueNv21Frame,
  }.entries) {
    test(
      '${c.key} -> PNG: valid, rotated, survives native buffer release',
      () async {
        final Uint8List first = YuvToPng.yuvToPng(c.value());
        // Hammer the allocator so a dangling buffer would be overwritten.
        for (int i = 0; i < 200; i++) {
          final Uint8List png = YuvToPng.yuvToPng(c.value());
          expect(png.sublist(0, 8), _pngSignature);
        }
        final (int w, int h, ByteData d) = await _decode(first);
        expect(w, 2);
        expect(h, 4);
        expect(_isRed(_px(d, w, 0, 0)), isTrue, reason: '${_px(d, w, 0, 0)}');
        expect(_isBlue(_px(d, w, 0, 3)), isTrue, reason: '${_px(d, w, 0, 3)}');
      },
    );

    test('${c.key} -> PNG front camera is mirrored', () async {
      final Uint8List png = YuvToPng.yuvToPng(
        c.value(),
        lensDirection: CameraLensDirection.front,
      );
      final (int w, int h, ByteData d) = await _decode(png);
      expect((w, h), (2, 4));
      expect(_isBlue(_px(d, w, 0, 0)), isTrue, reason: '${_px(d, w, 0, 0)}');
      expect(_isRed(_px(d, w, 0, 3)), isTrue, reason: '${_px(d, w, 0, 3)}');
    });
  }

  for (final bool front in [false, true]) {
    test(
      'yuv420 -> RGB -> PNG in Dart (${front ? 'front' : 'back'} camera)',
      () async {
        final RgbImage rgb = YuvToPng.yuvToRgb(
          _redBlueFrame(),
          lensDirection: front
              ? CameraLensDirection.front
              : CameraLensDirection.back,
        );
        final Uint8List png = encodePngRgba(rgb.bytes, rgb.width, rgb.height);

        final (int w, int h, ByteData d) = await _decode(png);
        expect((w, h), (2, 4));
        final topIsRed = !front;
        expect(_isRed(_px(d, w, 0, 0)), topIsRed, reason: '${_px(d, w, 0, 0)}');
        expect(_isBlue(_px(d, w, 0, 0)), !topIsRed);
        expect(
          _isRed(_px(d, w, 1, 3)),
          !topIsRed,
          reason: '${_px(d, w, 1, 3)}',
        );
        expect(_isBlue(_px(d, w, 1, 3)), topIsRed);
      },
    );
  }
}
