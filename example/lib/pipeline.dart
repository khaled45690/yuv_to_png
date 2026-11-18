import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:yuv_to_png/yuv_to_png.dart';

import 'png_encoder.dart';

/// The conversion strategies the example can compare.
enum Pipeline {
  /// YUV -> PNG, all in native code (`YuvToPng.yuvToPng`).
  nativePng(
    title: 'Native PNG',
    subtitle: 'YUV → PNG in C++',
    icon: Icons.bolt_rounded,
  ),

  /// YUV -> raw RGBA, no encoding at all (`YuvToPng.yuvToRgb`).
  rawRgb(
    title: 'Raw RGB',
    subtitle: 'YUV → RGBA pixels, no encoding',
    icon: Icons.grid_view_rounded,
  ),

  /// YUV -> raw RGBA natively, then PNG-encoded in Dart (in an isolate).
  dartPng(
    title: 'RGB → PNG (Dart)',
    subtitle: 'Native RGBA, PNG encoded in Dart',
    icon: Icons.compress_rounded,
  );

  const Pipeline({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// `yuvToRgb` only supports YUV420, so NV21 can only use the native PNG path.
  bool supports(ImageFormatGroup format) =>
      format == ImageFormatGroup.yuv420 || this == Pipeline.nativePng;
}

/// Result of converting one camera frame.
class FrameResult {
  FrameResult({
    required this.image,
    required this.outputBytes,
    required this.convertTime,
  });

  /// Decoded image, ready for a `RawImage`. The caller owns it.
  final ui.Image image;

  /// Size of the intermediate output (PNG file size, or raw RGBA size).
  final int outputBytes;

  /// Time spent producing [outputBytes] from the YUV frame.
  final Duration convertTime;
}

Future<FrameResult> runPipeline(
  Pipeline pipeline,
  CameraImage frame,
  CameraLensDirection lens,
) async {
  final Stopwatch sw = Stopwatch()..start();
  switch (pipeline) {
    case Pipeline.nativePng:
      final Uint8List png = YuvToPng.yuvToPng(frame, lensDirection: lens);
      sw.stop();
      return FrameResult(
        image: await _decodePng(png),
        outputBytes: png.length,
        convertTime: sw.elapsed,
      );

    case Pipeline.rawRgb:
      final RgbImage rgb = YuvToPng.yuvToRgb(frame, lensDirection: lens);
      sw.stop();
      return FrameResult(
        image: await _fromRgba(rgb),
        outputBytes: rgb.bytes.length,
        convertTime: sw.elapsed,
      );

    case Pipeline.dartPng:
      final RgbImage rgb = YuvToPng.yuvToRgb(frame, lensDirection: lens);
      // Encoding is CPU heavy, so keep it off the UI isolate.
      final Uint8List png = await Isolate.run(
        () => encodePngRgba(rgb.bytes, rgb.width, rgb.height),
      );
      sw.stop();
      return FrameResult(
        image: await _decodePng(png),
        outputBytes: png.length,
        convertTime: sw.elapsed,
      );
  }
}

Future<ui.Image> _decodePng(Uint8List png) async {
  final ui.Codec codec = await ui.instantiateImageCodec(png);
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

Future<ui.Image> _fromRgba(RgbImage rgb) {
  final Completer<ui.Image> completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgb.bytes,
    rgb.width,
    rgb.height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}
