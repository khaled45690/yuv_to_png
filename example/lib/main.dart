import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:yuv_to_png/yuv_to_png.dart';
import 'dart:ui' as ui;

/// Camera example home widget.
class CameraExampleHome extends StatefulWidget {
  /// Default Constructor
  const CameraExampleHome({super.key});

  @override
  State<CameraExampleHome> createState() {
    return _CameraExampleHomeState();
  }
}

StreamController<ui.Image> imageStream = StreamController<ui.Image>();

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  // This enum is from a different package, so a new value could be added at
  // any time. The example should keep working if that happens.
  // ignore: dead_code
  return Icons.camera;
}

void _logError(String code, String? message) {
  // ignore: avoid_print
  print('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

class _CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  XFile? imageFile;
  XFile? videoFile;
  VoidCallback? videoPlayerListener;
  String groupValue = "";
  bool enableAudio = true;
  int counter = 0;
  bool isbusy = false;

  // Counting pointers (number of user fingers on screen)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // _initializeCameraController(cameraController.description);
    }
  }
  // #enddocregion AppLifecycle

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera example'),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: controller != null && controller!.value.isRecordingVideo
                    ? Colors.redAccent
                    : Colors.grey,
                width: 3.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Center(
                child: _cameraPreviewWidget(),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            child: Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    children: [
                      const Text("nv21"),
                      Icon(getCameraLensIcon(CameraLensDirection.back)),
                      SizedBox(
                        width: 50.0,
                        child: Radio<String>(
                          groupValue: groupValue,
                          value: "nv21",
                          onChanged: (name) => onNewCameraSelected(
                              _cameras[0], ImageFormatGroup.nv21),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("yuv420"),
                      Icon(getCameraLensIcon(CameraLensDirection.back)),
                      SizedBox(
                        width: 50.0,
                        child: Radio<String>(
                          groupValue: groupValue,
                          value: "yuv420",
                          onChanged: (name) => onNewCameraSelected(
                              _cameras[0], ImageFormatGroup.yuv420),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Stop"),
                      Icon(getCameraLensIcon(CameraLensDirection.back)),
                      SizedBox(
                        width: 50.0,
                        child: Radio<String>(
                          groupValue: groupValue,
                          value: "Stop",
                          onChanged: (name) async {
                            groupValue = "Stop";

                            await controller?.stopImageStream();
                            // controller?.dispose();
                            // controller = null;
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return StreamBuilder(
        stream: imageStream.stream,
        builder: (context, snapshot) {
          if (snapshot.data == null) return const SizedBox();
          return RawImage(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.cover,
            // pass dart:ui.Image here
            image: snapshot.data,
          );
        },
      );
    }
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final CameraController cameraController = controller!;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  Future<void> onNewCameraSelected(
      CameraDescription cameraDescription, ImageFormatGroup format) async {
    groupValue = format.name;
    setState(() {});
    if (controller != null) {
      try {
        await controller?.stopImageStream();
      } catch (e) {
        print(e);
      }
      await controller?.dispose();
      controller = null;
      return _initializeCameraController(cameraDescription, format);
    } else {
      return _initializeCameraController(cameraDescription, format);
    }
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription, ImageFormatGroup format) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: format,
    );
    controller = cameraController;

    try {
      await cameraController.initialize();

      cameraController.startImageStream(
        (CameraImage cameraImage) async {
          if (counter > 5 && controller != null) {
            counter = 0;
            Uint8List png = YuvToPng.yuvToPng(cameraImage,
                lensDirection: cameraController.description.lensDirection);
              
            ui.decodeImageFromList(png, (result) async {
              InputImageMetadata metadata = InputImageMetadata(
                  size: Size( cameraImage.width.toDouble(), cameraImage.height.toDouble()),
                  rotation: InputImageRotation.rotation90deg,
                  format: InputImageFormat.nv21,
                  bytesPerRow: cameraImage.planes[0].bytesPerRow);

              InputImage inputImage = InputImage.fromBytes(
                  bytes: cameraImage.planes[0].bytes,
                  metadata: metadata);
              final TextRecognizer _textRecognizer = TextRecognizer();
              final recognizedText =
                  await _textRecognizer.processImage(inputImage);
              print("recognizedText.text");
              print(recognizedText.text);
              imageStream.sink.add(result);
            });
          } else {
            counter++;
          }
        },
      );

      // FlutterImageCompress.compressWithList(
      //   image,
      //   quality: 20,
      // ).then((value) =>);

      // });
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          showInSnackBar('You have denied camera access.');
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable camera access.');
        case 'CameraAccessRestricted':
          // iOS only
          showInSnackBar('Camera access is restricted.');
        case 'AudioAccessDenied':
          showInSnackBar('You have denied audio access.');
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable audio access.');
        case 'AudioAccessRestricted':
          // iOS only
          showInSnackBar('Audio access is restricted.');
        default:
          _showCameraException(e);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onAudioModeButtonPressed() {
    enableAudio = !enableAudio;
    if (controller != null) {
      // onNewCameraSelected(controller!.description);
    }
  }

  Future<void> onCaptureOrientationLockButtonPressed() async {
    try {
      if (controller != null) {
        final CameraController cameraController = controller!;
        if (cameraController.value.isCaptureOrientationLocked) {
          await cameraController.unlockCaptureOrientation();
          showInSnackBar('Capture orientation unlocked');
        } else {
          await cameraController.lockCaptureOrientation();
          showInSnackBar(
              'Capture orientation locked to ${cameraController.value.lockedCaptureOrientation.toString().split('.').last}');
        }
      }
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

/// CameraApp is the Main Application.
class CameraApp extends StatelessWidget {
  /// Default Constructor
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CameraExampleHome(),
    );
  }
}

List<CameraDescription> _cameras = <CameraDescription>[];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    _logError(e.code, e.description);
  }
  runApp(const CameraApp());
}
