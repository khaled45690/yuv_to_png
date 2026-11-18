import 'dart:typed_data';

/// A raw, uncompressed image returned by [YuvToPng.yuvToRgb].
///
/// [bytes] holds [width] x [height] pixels in RGBA8888 order (4 bytes per
/// pixel: R, G, B, A with A always 255). Rows are tightly packed, so
/// `bytes.length == width * height * 4`.
///
/// The image is already rotated to portrait (and mirrored for the front
/// camera), so [width] and [height] are the camera frame's height and width.
class RgbImage {
  const RgbImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// Number of bytes per pixel in [bytes].
  static const int bytesPerPixel = 4;
}
