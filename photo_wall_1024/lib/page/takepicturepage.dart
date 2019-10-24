import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:photo_wall_1024/development/logger.dart';
import 'package:photo_wall_1024/page/viewpicturepage.dart';
import 'package:photo_wall_1024/utils/camera.dart';


// A screen that allows users to take a picture using a given camera.
class TakePicturePage extends StatefulWidget {

  const TakePicturePage({
    Key key,
  }) : super(key: key);

  @override
  TakePicturePageState createState() => TakePicturePageState();
}

class TakePicturePageState extends State<TakePicturePage> {

  CameraCore _cameraCore = cameraCoreInstance;

  Future<void> _setupCamera() async {
    await _cameraCore.openCamera();
  }

  Future<void> _toggleCamera() async {
    _cameraCore.toggleCamera(false);

    setState(() {});
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _cameraCore.closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug('building new state UI');
    return Scaffold(
      body: FutureBuilder<void>(
        future: _setupCamera(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            final size = MediaQuery
                .of(context)
                .size;
            final controller = _cameraCore.getCamera();
            final direction = _cameraCore.getCameraDirection();

            return Stack(
                children: [
                  ClipRect(
                    child: Container(
                      child: Transform.scale(
                        scale: controller.value.aspectRatio / size.aspectRatio,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: CameraPreview(controller),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 15,
                    child: IconButton(
                        icon: Icon(
                          direction == CameraLensDirection.back
                              ? Icons.camera_front : Icons.camera_rear,
                          color: Colors.white,
                        ),
                        onPressed: _toggleCamera,
                        iconSize: 32
                    ),
                  )
                ]
            );
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(

        child: Icon(Icons.camera),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
//            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.

              (await getApplicationDocumentsDirectory()).path,
              '${DateTime
                  .now()
                  .millisecondsSinceEpoch}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            await _cameraCore.getCamera().takePicture(path);
            Logger.debug("file is saved in [$path]");

            Navigator.push(
              context,
              MaterialPageRoute(
//                builder: (context) => DisplayPictureScreen(
//                    imagePath: path,
//                    direction: _cameraCore.getCameraDirection(),
//                ),
                builder: (context) =>
                    ViewPicturePage(
                      filePath: path,
                      direction: _cameraCore.getCameraDirection(),
                    ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            Logger.error(e);
          }
        },
      ),
    );
  }
}
