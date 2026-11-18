import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'pipeline.dart';

const Color _bg = Color(0xFF08080D);
const Color _accent = Color(0xFF8B7CFF);
const Color _accent2 = Color(0xFF38E1C6);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<CameraDescription> cameras = const <CameraDescription>[];
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Camera error: ${e.code} ${e.description ?? ''}');
  }
  runApp(YuvLabApp(cameras: cameras));
}

class YuvLabApp extends StatelessWidget {
  const YuvLabApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YUV Lab',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.dark,
        ),
      ),
      home: LabPage(cameras: cameras),
    );
  }
}

/// Numbers shown in the stat pills.
class _Stats {
  const _Stats({
    this.fps = 0,
    this.convertMs = 0,
    this.outputBytes = 0,
    this.width = 0,
    this.height = 0,
  });

  final double fps;
  final double convertMs;
  final int outputBytes;
  final int width;
  final int height;
}

class LabPage extends StatefulWidget {
  const LabPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> with WidgetsBindingObserver {
  CameraController? _controller;
  ImageFormatGroup _format = ImageFormatGroup.yuv420;
  Pipeline _pipeline = Pipeline.rawRgb;
  int _cameraIndex = 0;

  bool _running = false; // user pressed Start
  bool _busy = false; // a frame is being converted
  bool _switching = false; // camera is being (re)opened

  final ValueNotifier<ui.Image?> _image = ValueNotifier<ui.Image?>(null);
  final ValueNotifier<_Stats> _stats = ValueNotifier<_Stats>(const _Stats());

  final Stopwatch _fpsWatch = Stopwatch();
  int _fpsFrames = 0;
  double _fps = 0;
  double _smoothedMs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final int back = widget.cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _cameraIndex = back >= 0 ? back : 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _running = false;
    _closeCamera();
    _image.value?.dispose();
    _image.dispose();
    _stats.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_running) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _closeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _openCamera();
    }
  }

  // ---------------------------------------------------------------- camera

  Future<void> _openCamera() async {
    if (_switching || widget.cameras.isEmpty) return;
    _switching = true;
    try {
      await _closeCamera();
      final CameraController controller = CameraController(
        widget.cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: _format,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted || !_running) {
        await _closeCamera();
        return;
      }
      _fpsWatch
        ..reset()
        ..start();
      _fpsFrames = 0;
      await controller.startImageStream(_onFrame);
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      _running = false;
      await _closeCamera();
      _toast(
        e.code.startsWith('CameraAccess')
            ? 'Camera permission denied'
            : 'Camera error: ${e.description ?? e.code}',
      );
      if (mounted) setState(() {});
    } finally {
      _switching = false;
    }
  }

  Future<void> _closeCamera() async {
    final CameraController? controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    await controller.dispose();
  }

  Future<void> _onFrame(CameraImage frame) async {
    if (_busy || !_running || !mounted) return;
    _busy = true;
    try {
      final CameraLensDirection lens =
          widget.cameras[_cameraIndex].lensDirection;
      final FrameResult result = await runPipeline(_pipeline, frame, lens);
      if (!mounted || !_running) {
        result.image.dispose();
        return;
      }

      final ui.Image? old = _image.value;
      _image.value = result.image;
      if (old != null) {
        // Dispose only after the new image has been painted.
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }

      final double ms = result.convertTime.inMicroseconds / 1000;
      _smoothedMs = _smoothedMs == 0 ? ms : _smoothedMs * 0.8 + ms * 0.2;
      _fpsFrames++;
      final int elapsed = _fpsWatch.elapsedMilliseconds;
      if (elapsed >= 500) {
        _fps = _fpsFrames * 1000 / elapsed;
        _fpsFrames = 0;
        _fpsWatch
          ..reset()
          ..start();
      }
      _stats.value = _Stats(
        fps: _fps,
        convertMs: _smoothedMs,
        outputBytes: result.outputBytes,
        width: result.image.width,
        height: result.image.height,
      );
    } catch (e) {
      _running = false;
      _closeCamera();
      _toast('Conversion failed: $e');
      if (mounted) setState(() {});
    } finally {
      _busy = false;
    }
  }

  // --------------------------------------------------------------- actions

  Future<void> _toggleRun() async {
    if (_running) {
      setState(() => _running = false);
      await _closeCamera();
      return;
    }
    if (widget.cameras.isEmpty) {
      _toast('No camera found on this device');
      return;
    }
    setState(() => _running = true);
    await _openCamera();
  }

  void _selectFormat(ImageFormatGroup format) {
    if (format == _format) return;
    setState(() {
      _format = format;
      if (!_pipeline.supports(format)) _pipeline = Pipeline.nativePng;
    });
    if (_running) _openCamera();
  }

  void _selectPipeline(Pipeline pipeline) {
    if (!pipeline.supports(_format)) return;
    setState(() {
      _pipeline = pipeline;
      _smoothedMs = 0;
    });
  }

  void _flipCamera() {
    if (widget.cameras.length < 2) return;
    setState(() => _cameraIndex = (_cameraIndex + 1) % widget.cameras.length);
    if (_running) _openCamera();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Preview(image: _image, running: _running),
          const IgnorePointer(child: _EdgeGradients()),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _TopBar(stats: _stats, running: _running),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _ControlPanel(
              format: _format,
              pipeline: _pipeline,
              running: _running,
              starting: _switching,
              canFlip: widget.cameras.length > 1,
              onFormat: _selectFormat,
              onPipeline: _selectPipeline,
              onToggle: _toggleRun,
              onFlip: _flipCamera,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ preview

class _Preview extends StatelessWidget {
  const _Preview({required this.image, required this.running});

  final ValueNotifier<ui.Image?> image;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ui.Image?>(
      valueListenable: image,
      builder: (context, img, _) {
        if (img == null) return _EmptyState(running: running);
        return RawImage(
          image: img,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 0.9,
          colors: [Color(0xFF1B1840), _bg],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 220),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_accent, _accent2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.45),
                      blurRadius: 36,
                    ),
                  ],
                ),
                child: running
                    ? const Padding(
                        padding: EdgeInsets.all(26),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.videocam_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                running ? 'Opening camera…' : 'YUV Lab',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                running
                    ? 'Waiting for the first frame'
                    : 'Pick a pipeline and press Start',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EdgeGradients extends StatelessWidget {
  const _EdgeGradients();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.18, 0.55, 1],
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

// ------------------------------------------------------------------ top bar

class _TopBar extends StatelessWidget {
  const _TopBar({required this.stats, required this.running});

  final ValueNotifier<_Stats> stats;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_Stats>(
      valueListenable: stats,
      builder: (context, s, _) {
        final bool live = running && s.fps > 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'YUV Lab',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 10),
                _LiveDot(live: live),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(
                  icon: Icons.speed_rounded,
                  label: 'FPS',
                  value: live ? s.fps.toStringAsFixed(1) : '–',
                ),
                _StatPill(
                  icon: Icons.timer_outlined,
                  label: 'Convert',
                  value: live ? '${s.convertMs.toStringAsFixed(1)} ms' : '–',
                ),
                _StatPill(
                  icon: Icons.data_object_rounded,
                  label: 'Output',
                  value: live ? _formatBytes(s.outputBytes) : '–',
                ),
                _StatPill(
                  icon: Icons.aspect_ratio_rounded,
                  label: 'Size',
                  value: live ? '${s.width}×${s.height}' : '–',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.live});

  final bool live;

  @override
  Widget build(BuildContext context) {
    final Color color = live ? const Color(0xFFFF4D6D) : Colors.white24;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            live ? 'LIVE' : 'IDLE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: live ? Colors.white : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 14,
      tint: 0.38,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _accent2),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ control panel

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.format,
    required this.pipeline,
    required this.running,
    required this.starting,
    required this.canFlip,
    required this.onFormat,
    required this.onPipeline,
    required this.onToggle,
    required this.onFlip,
  });

  final ImageFormatGroup format;
  final Pipeline pipeline;
  final bool running;
  final bool starting;
  final bool canFlip;
  final ValueChanged<ImageFormatGroup> onFormat;
  final ValueChanged<Pipeline> onPipeline;
  final VoidCallback onToggle;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.66;
    return _Glass(
      radius: 30,
      tint: 0.62,
      borderOnlyTop: true,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // The options scroll on short screens; Start/Stop stays pinned.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('INPUT FORMAT'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ImageFormatGroup>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: ImageFormatGroup.yuv420,
                                label: Text('YUV420'),
                                icon: Icon(Icons.layers_rounded, size: 18),
                              ),
                              ButtonSegment(
                                value: ImageFormatGroup.nv21,
                                label: Text('NV21'),
                                icon: Icon(Icons.view_stream_rounded, size: 18),
                              ),
                            ],
                            selected: {format},
                            onSelectionChanged: (s) => onFormat(s.first),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _SectionLabel('PIPELINE'),
                        const SizedBox(height: 8),
                        for (final Pipeline p in Pipeline.values) ...[
                          _PipelineTile(
                            pipeline: p,
                            selected: p == pipeline,
                            enabled: p.supports(format),
                            onTap: () => onPipeline(p),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (format == ImageFormatGroup.nv21)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Raw RGB is available for YUV420 only.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StartButton(
                        running: running,
                        starting: starting,
                        onPressed: onToggle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: canFlip ? onFlip : null,
                      tooltip: 'Switch camera',
                      iconSize: 26,
                      padding: const EdgeInsets.all(15),
                      icon: const Icon(Icons.flip_camera_android_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: Colors.white54,
      ),
    );
  }
}

class _PipelineTile extends StatelessWidget {
  const _PipelineTile({
    required this.pipeline,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Pipeline pipeline;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = selected ? _accent : Colors.white12;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? _accent.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: selected
                      ? const LinearGradient(colors: [_accent, _accent2])
                      : null,
                  color: selected ? null : Colors.white10,
                ),
                child: Icon(pipeline.icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pipeline.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      pipeline.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('on'),
                        color: _accent2,
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        key: ValueKey('off'),
                        color: Colors.white24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.running,
    required this.starting,
    required this.onPressed,
  });

  final bool running;
  final bool starting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = running
        ? const [Color(0xFFFF4D6D), Color(0xFFFF8A5B)]
        : const [_accent, Color(0xFF5B8CFF)];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: starting ? null : onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 26,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  running ? 'Stop' : 'Start',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- glass card

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    required this.radius,
    this.tint = 0.5,
    this.padding,
    this.borderOnlyTop = false,
  });

  final Widget child;
  final double radius;
  final double tint;
  final EdgeInsetsGeometry? padding;
  final bool borderOnlyTop;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = borderOnlyTop
        ? BorderRadius.vertical(top: Radius.circular(radius))
        : BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: borderOnlyTop ? double.infinity : null,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            color: const Color(0xFF12111C).withValues(alpha: tint),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: child,
        ),
      ),
    );
  }
}
