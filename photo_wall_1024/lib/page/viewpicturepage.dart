import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:fluttie/fluttie.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_wall_1024/development/logger.dart';

class ViewPicturePage extends StatefulWidget {
  final String filePath;
  final CameraLensDirection direction;

  const ViewPicturePage({
    Key key,
    @required this.filePath,
    this.direction,
  }) : super(key: key);

  @override
  _ViewPicturePageState createState() => _ViewPicturePageState();
}

class _ViewPicturePageState extends State<ViewPicturePage> {
  String statePrompt = '';
  Timer _autoCloseTimer;

  var _futureBuilderFuture;

  FluttieAnimationController lottiAnim;

  bool lottiAnimReady = false;

//  Face faceInImage;

  @override
  void initState() {
    super.initState();

    Map params = {
      'filePath': widget.filePath,
      'direction': widget.direction,
    };

    _futureBuilderFuture = _reviewImage(params);

//    prepareAnimation();
  }

  @override
  dispose() {
    super.dispose();

    if (lottiAnim != null) {
      lottiAnim.dispose();
    }
  }

  static _preprocessImage(Map params) {
    String filePath = params['filePath'];
    CameraLensDirection direction = params['direction'];

    Logger.info('preprocess image: file = $filePath, direction = $direction');

    int start, end;

    start = new DateTime.now().millisecondsSinceEpoch;
    img.Image image = img.decodeImage(File(filePath).readAsBytesSync());
    end = new DateTime.now().millisecondsSinceEpoch;
    Logger.debug('load image in ${end - start}');

    start = new DateTime.now().millisecondsSinceEpoch;
    img.Image resize = img.copyResize(image, width: 640);
    end = new DateTime.now().millisecondsSinceEpoch;
    Logger.debug('resize image in ${end - start}');

    start = new DateTime.now().millisecondsSinceEpoch;
    img.Image flipImage = direction == CameraLensDirection.front
        ? img.flip(resize, img.Flip.horizontal)
        : resize;
    end = new DateTime.now().millisecondsSinceEpoch;
    Logger.debug('flip image in ${end - start}');

    start = new DateTime.now().millisecondsSinceEpoch;
    File(filePath)..writeAsBytesSync(img.encodePng(flipImage));
    end = new DateTime.now().millisecondsSinceEpoch;
    Logger.debug('save image in ${end - start}');
  }

  static _compressImageFastStep1(Map params) async {
    String filePath = params['filePath'];
    CameraLensDirection direction = params['direction'];

    Logger.debug('preprocess image fast[1]: file = $filePath, direction = $direction');

    int start, end;

    start = new DateTime.now().millisecondsSinceEpoch;
    var bytes = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: 640,
      format: CompressFormat.jpeg,
      quality: 80
    );

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true, mode: FileMode.write);
    end = new DateTime.now().millisecondsSinceEpoch;
    Logger.debug('resize image in ${end - start}');
  }

  static _compressImageFastStep2(Map params) {
    String filePath = params['filePath'];
    CameraLensDirection direction = params['direction'];

    Logger.debug('preprocess image fast[2]: file = $filePath, direction = $direction');

    int start, end;

    start = new DateTime.now().millisecondsSinceEpoch;
    img.Image resize = img.decodeImage(File(filePath).readAsBytesSync());
    end = new DateTime.now().millisecondsSinceEpoch;
    Logger.debug('load image again in ${end - start}');

    start = new DateTime.now().millisecondsSinceEpoch;
    img.Image flipImage = direction == CameraLensDirection.front
        ? img.flip(resize, img.Flip.horizontal)
        : resize;
//    img.Image flipImage = resize;
    end = new DateTime.now().millisecondsSinceEpoch;
    Logger.debug('flip image in ${end - start}');

    start = new DateTime.now().millisecondsSinceEpoch;
    File(filePath)..writeAsBytesSync(img.encodePng(flipImage));
    end = new DateTime.now().millisecondsSinceEpoch;
    Logger.debug('save image in ${end - start}');
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug(
        'showing the review: filePath = ${widget.filePath}, direction = ${widget.direction}');

    return Scaffold(
      body: FutureBuilder(
          future: _futureBuilderFuture,
          builder: (context, snapshot) {
            Logger.debug('snapshot state: ${snapshot.connectionState}');
            if (snapshot.connectionState == ConnectionState.done) {
//            if (false) {
//
//
//              String name = faceInImage.name;
//
//              String prob = FaceUiHelper.getProbabilityString(faceInImage);
//              Color probColor = FaceUiHelper.getProbabilityColor(faceInImage);
//
//              Map segments = FaceUiHelper.getNameSegments(faceInImage);
//              String firstName = segments['first'];
//              String lastName = segments['last'];

              return WillPopScope(
                onWillPop: _handleWillPop,
                child: Container(
                  child: Stack(alignment: Alignment.bottomCenter, children: [
                    Positioned.fill(
                      child:
                          Image.file(File(widget.filePath), fit: BoxFit.cover),
                    ),
//                    Positioned.fill(
//                        child: DecoratedBox(
//                      decoration: BoxDecoration(
//                        gradient: LinearGradient(
//                          begin: (name == null
//                              ? FractionalOffset.bottomCenter
//                              : FractionalOffset.bottomRight),
//                          end: FractionalOffset(0.5, 0.3),
//                          colors: [
//                            Colors.black.withOpacity(.8),
//                            Colors.black12.withOpacity(0.0),
//                          ],
//                        ),
//                      ),
//                    )),
//                    Wrap(children: [
//                      Column(
//                        mainAxisSize: MainAxisSize.min,
//                        crossAxisAlignment: CrossAxisAlignment.end,
//                        children: <Widget>[
//                          Offstage(
//                            offstage: (name == null),
//                            child: Padding(
//                              padding: EdgeInsets.only(right: 20, bottom: 4),
//                              child: Text(prob,
//                                  textAlign: TextAlign.left,
//                                  style: new TextStyle(
//                                    color: probColor,
//                                    fontWeight: FontWeight.bold,
//                                    fontStyle: FontStyle.italic,
//                                    fontSize: 72.0,
//                                  )),
//                            ),
//                          ),
//                          Container(
//                            alignment: (name == null
//                                ? Alignment.center
//                                : Alignment.centerRight),
//                            padding: EdgeInsets.only(
//                                right: (name == null ? 0 : 20), bottom: 20),
//                            child: (name == null
//                                ? Text("No face detected",
//                                    textAlign: TextAlign.right,
//                                    style: new TextStyle(
//                                      color: Colors.white70,
//                                      fontWeight: FontWeight.bold,
//                                      fontStyle: FontStyle.italic,
//                                      fontSize: 36.0,
//                                    ))
//                                : Row(
//                                    crossAxisAlignment: CrossAxisAlignment.end,
//                                    mainAxisSize: MainAxisSize.min,
//                                    children: [
//                                      Text(lastName,
//                                          textAlign: TextAlign.right,
//                                          style: new TextStyle(
//                                            color: Colors.white,
//                                            fontWeight: FontWeight.bold,
//                                            fontStyle: FontStyle.italic,
//                                            fontSize: 48.0,
//                                          )),
//                                      Padding(
//                                          padding: EdgeInsets.only(
//                                              left: 4, bottom: 4),
//                                          child: Text(firstName,
//                                              textAlign: TextAlign.right,
//                                              style: new TextStyle(
//                                                color: Colors.white,
//                                                fontWeight: FontWeight.bold,
//                                                fontStyle: FontStyle.italic,
//                                                fontSize: 36.0,
//                                              ))),
//                                    ],
//                                  )),
//                          ),
//                        ],
//                      ),
//                    ]),
                  ]),
                  constraints: BoxConstraints.expand(),
                ),
              );
            } else {
              return WillPopScope(
                onWillPop: _handleWillPop,
                child: Container(
                  color: Colors.white,
                  child: Center(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(statePrompt,
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                            color: Colors.deepOrangeAccent,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            fontSize: 18.0,
                          )),
                      Container(
                        height: 100,
//                            child: FluttieAnimation(mLottiAnim)
                        child: Image.asset('assets/animations/profile.gif'),
                      )
                    ],
                  )),
                ),
              );
            }
          }),
    );
  }

  Future<bool> _handleWillPop() async {
    if (_autoCloseTimer != null) {
      Logger.debug('auto-close timer is cancelled.');
      _autoCloseTimer.cancel();
      _autoCloseTimer = null;
    }

    Navigator.pop(context);

    return true;
  }

  Future<void> _reviewImage(Map params) async {
    setState(() {
      statePrompt = 'loading image from file...';
    });

    var start, end;
    bool useFastAlgorithm = true;
    Logger.debug('process image: useFastAlgorithm = $useFastAlgorithm');

    if (useFastAlgorithm) {
      start = new DateTime.now().millisecondsSinceEpoch;
      await _compressImageFastStep1(params);
      await compute(_compressImageFastStep2, params);
      end = new DateTime.now().millisecondsSinceEpoch;
      Logger.debug('pre-process image fast is accomplished in ${end - start} milliseconds.');
    } else {
      start = new DateTime.now().millisecondsSinceEpoch;
      await compute(_preprocessImage, params);
      end = new DateTime.now().millisecondsSinceEpoch;
      Logger.debug('pre-process image is accomplished in ${end - start} milliseconds.');
    }

    _autoClose();
  }

  void _autoClose() {
    _autoCloseTimer = new Timer(Duration(seconds: 5), () {
      Navigator.pop(context);
      Navigator.pop(context);
    });
  }

  void prepareAnimation() async {
    bool canBeUsed = await Fluttie.isAvailable();
    if (!canBeUsed) {
      Logger.debug("Animations are not supported on this platform");
      return;
    }

    var instance = Fluttie();

    var composition =
        await instance.loadAnimationFromAsset("assets/animations/connection_error.json");
    Logger.debug('load composition: $composition');

    lottiAnim = await instance.prepareAnimation(composition,
        repeatCount: const RepeatCount.infinite(),
        repeatMode: RepeatMode.START_OVER);
    Logger.debug('prepare animation: $lottiAnim');

    Logger.debug('start animation');

    if (mounted) {
      setState(() {
        Logger.debug('set animation ready');

        lottiAnimReady = true;
        lottiAnim.start();
      });
    }
  }
}
