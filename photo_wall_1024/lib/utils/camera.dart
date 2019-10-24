import 'package:camera/camera.dart';

class CameraCore {

  CameraController _controller;
  CameraLensDirection _currentDirection;

  Future<void> initCamera() async {
    _currentDirection = CameraLensDirection.front;

    _switchCameraTo(CameraLensDirection.front);
  }

  Future<void> openCamera() async {
    if (_controller != null) {
      print('camera is ready, skip');

      return;
    }

    await _switchCameraTo(_currentDirection);
  }

  Future<void> toggleCamera(bool syncCamera) async {
    CameraLensDirection target;
    if (_currentDirection == CameraLensDirection.front) {
      target = CameraLensDirection.back;
    } else {
      target = CameraLensDirection.front;
    }

    print('current = $_currentDirection, target = $target}');

    _currentDirection = target;

    closeCamera();
    if (syncCamera) {
      _switchCameraTo(target);
    }
  }

  CameraController getCamera() {
    return _controller;
  }

  CameraLensDirection getCameraDirection() {
    return _currentDirection;
  }

  Future<void> _switchCameraTo(CameraLensDirection direction) async {
    print('switching camera to: $direction');

    if (_controller != null) {
      await _controller.dispose();
    }

    final cameras = await availableCameras();

    var selectedCamera;
    for (selectedCamera in cameras) {
      if (selectedCamera.lensDirection == direction) {
        break;
      }
    }

    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      selectedCamera,
      // Define the resolution to use.
      ResolutionPreset.high,
    );

    // Next, initialize the controller. This returns a Future.
    await _controller.initialize();
  }

  void closeCamera() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    _controller = null;
  }

}

CameraCore cameraCoreInstance = CameraCore();