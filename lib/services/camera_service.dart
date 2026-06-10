import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  bool _initialized = false;

  Future<void> initialize() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _initialized = false;
        return;
      }
      final cameras = await availableCameras();
      // Preferir cámara frontal para capturar al intruso
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<String?> captureIntruder() async {
    if (!_initialized || _controller == null) {
      await initialize();
    }
    try {
      if (!_initialized) return null;
      final image = await _controller!.takePicture();
      return image.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _initialized = false;
  }
}
