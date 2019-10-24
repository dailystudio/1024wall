import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_stetho/flutter_stetho.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:photo_wall_1024/database/database.dart';
import 'package:photo_wall_1024/events/events.dart';
import 'package:photo_wall_1024/page/takepicturepage.dart';
import 'package:photo_wall_1024/ui/photogridview.dart';
import 'package:photo_wall_1024/utils/camera.dart';
import 'development/logger.dart';

Color primaryColor = Colors.deepOrange;
final RouteObserver<PageRoute> _routeObserver = RouteObserver<PageRoute>();
Set<Point<int>> _occupied = Set();

void main() {
  Logger.setDebugEnabled(!kReleaseMode);
  Logger.info(
      'applicatio is running in ${kReleaseMode ? "release" : "debug"} mode');

  if (!kReleaseMode) {
    Stetho.initialize();
  }

  cameraCoreInstance.initCamera();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Wall for 1024',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primaryColor: primaryColor,
        accentColor: primaryColor,
        primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white)),
      ),
      home: MyHomePage(title: 'Photo Wall for 1024'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver, RouteAware {
  ScrollController _faceScrollController = ScrollController();
  bool _hasNewFaces = false;

  Future<List<Photo>> _fetchPhotos() async {
    PhotoDatabase db = new PhotoDatabase();

    await db.open();
    final List<Photo> faces = await db.listPhotos();
    db.close();

    if (faces.length % 2 == 0) {
      faces.add(PhotoPlaceHolder());
    }

    return faces;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    eventBus.on<NewPhotoEvent>().listen((event) {
      print('new event: $event');

      _hasNewFaces = true;
    });

    eventBus.on<UpdatePhotoEvent>().listen((event) {
      print('new event: $event');

      setState(() {});
    });
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('life cycle state: $state');
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void didPush() {}

  @override
  void didPopNext() {
    if (_hasNewFaces) {
      setState(() {
        new Timer(Duration(seconds: 1), () {
          _faceScrollController.animateTo(0,
              duration: Duration(milliseconds: 1000), curve: Curves.ease);
          _hasNewFaces = false;
        });
      });
    }
  }

  void _takePicture() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePicturePage(),
      ),
    );
  }

  void _initCells() {
    _occupied.clear();

    /* 1 */
    _occupied.add(Point(1, 1));
    _occupied.add(Point(1, 3));
    _occupied.add(Point(1, 5));
    _occupied.add(Point(1, 7));
    _occupied.add(Point(1, 9));

    /* 0 */
    _occupied.add(Point(4, 1));
    _occupied.add(Point(4, 3));
    _occupied.add(Point(4, 5));
    _occupied.add(Point(4, 7));
    _occupied.add(Point(4, 9));
    _occupied.add(Point(6, 1));
    _occupied.add(Point(8, 1));
    _occupied.add(Point(8, 3));
    _occupied.add(Point(8, 5));
    _occupied.add(Point(8, 7));
    _occupied.add(Point(8, 9));
    _occupied.add(Point(6, 9));

    /* 2 */
    _occupied.add(Point(11, 1));
    _occupied.add(Point(13, 1));
    _occupied.add(Point(15, 1));
    _occupied.add(Point(15, 3));
    _occupied.add(Point(15, 5));
    _occupied.add(Point(13, 5));
    _occupied.add(Point(11, 5));
    _occupied.add(Point(11, 7));
    _occupied.add(Point(11, 9));
    _occupied.add(Point(13, 9));
    _occupied.add(Point(15, 9));

    /* 4 */
    _occupied.add(Point(18, 1));
    _occupied.add(Point(22, 1));
    _occupied.add(Point(18, 3));
    _occupied.add(Point(22, 3));
    _occupied.add(Point(18, 5));
    _occupied.add(Point(20, 5));
    _occupied.add(Point(22, 5));
    _occupied.add(Point(22, 7));
    _occupied.add(Point(22, 9));
  }

  Future<ui.Image> _loadPhotoFrame(String frameFile) async {
    Logger.debug("loading frame ... [$frameFile]");

    Completer c = new Completer<ui.Image>();
    ByteData data = await rootBundle.load(frameFile);

    Uint8List bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    ui.decodeImageFromList(bytes, (ui.Image img) {
      Logger.debug("frame loaded... [$img]");

      c.complete(img);
    });

    return c.future;
  }

  Future<ui.Image> _loadImage(File photoFile) async {
    Logger.debug("loading image ... [$photoFile]");

    Completer c = new Completer<ui.Image>();
    Uint8List data = photoFile.readAsBytesSync();
    ui.decodeImageFromList(data, (ui.Image img) {
      Logger.debug("image loaded... [$img]");

      c.complete(img);
    });

    return c.future;
  }

  void _generate() async {
    ui.Image frame = await _loadPhotoFrame('assets/images/photo_frame_red.png');
    _initCells();

    List<Photo> photos = await _fetchPhotos();
    Logger.debug('photoes to use: $photos');
    var maxSize = photos.length;

    var col = 24;
    var row = 11;

    var cellWidth = 300.0;
    var cellHeight = 300.0;

    var width = col * cellWidth;
    var height = row * cellHeight;

    double offsetX = 0;
    double offsetY = 0;

    Logger.debug('generating the photo wall ...');
    var pictureRecorder = ui.PictureRecorder();
    var canvas = Canvas(pictureRecorder);

    Paint bgPaint = Paint();
    bgPaint..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    Paint linePaint = Paint();
    linePaint..color = Colors.deepOrange;
    linePaint..strokeWidth = 3;

/*
    for (double x = offsetX; x < offsetX + width + cellWidth; x += cellWidth) {
      canvas.drawLine(Offset(x, offsetY), Offset(x, offsetY + height), linePaint);
    }

    for (double y = offsetY; y < offsetY + height + cellHeight; y += cellHeight) {
      canvas.drawLine(Offset(offsetX, y), Offset(offsetX + width, y), linePaint);
    }
*/

    Paint fillPaint = Paint();
    fillPaint..color = Colors.deepOrange;
    fillPaint..style = PaintingStyle.fill;

    Rect r;
    Rect srcRect;
    Rect dstRect;
    var photo;
    var index;
    var key;
    ui.Image image;
    var cache = Map<String, ui.Image>();
    double scale;
    for (Point p in _occupied) {
      if (p.x < 0 || p.x >= col || p.y < 0 || p.y >= row) {
        continue;
      }

      int min = 0, max = maxSize - 1;
      index = min + Random().nextInt(max - min);
      photo = photos[index];
      key = path.basename(photo.file);
      Logger.debug("pick $index: $photo to fill, key = $key");

      if (cache.containsKey(key)) {
        image = cache[key];
      } else {
        image = await _loadImage(File(photo.file));
        image = await decorateImage(image, frame, -10 / 180 * 3.14, 50, 100);
        cache[key] = image;
      }

//      r = Rect.fromLTWH(offsetX + p.x * cellWidth, offsetY + p.y * cellHeight,
//          cellWidth, cellHeight);
//      canvas.drawRect(r, fillPaint);

      scale = _calculateScale(
          Size(image.width.toDouble(), image.height.toDouble()),
          Size(cellWidth, cellHeight));

      dstRect = Rect.fromLTWH(offsetX + p.x * cellWidth,
          offsetY + p.y * cellHeight, cellWidth, cellHeight);

      double srcWidth = dstRect.width / scale;
      double srcHeight = dstRect.height / scale;
      double srcX = (image.width - srcWidth) / 2.0;
      double srcY = (image.height - srcHeight) / 2.0;

      srcRect =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      dstRect = Rect.fromLTWH(offsetX + p.x * cellWidth,
          offsetY + p.y * cellHeight, image.width * scale, image.height * scale);
      canvas.drawImageRect(image, srcRect, dstRect, fillPaint);
    }

    var pic = pictureRecorder.endRecording();
    ui.Image img = await pic.toImage(width.round(), height.round());
    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    var buffer = byteData.buffer.asUint8List();

    String outputFile = '/sdcard/1.png';
    new File(outputFile).writeAsBytes(buffer);
    Logger.debug('generated photo wall is saved in [$outputFile]');
  }

  Future<ui.Image> decorateImage(
      ui.Image image, ui.Image frame, double angle, double x, double y) async {
    var pictureRecorder = ui.PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);

    Paint fillPaint = Paint();

    ui.Image scaled = await scaleImage(image, .415);
    ui.Image cropped = await cropImage(scaled, scaled.width, scaled.width);
    ui.Image rotated = await rotatedImage(cropped, angle);
    canvas.drawImage(frame, Offset(0, 0), fillPaint);
//    canvas.drawRect(
//        Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
//        Paint()..color = Colors.black);
    canvas.drawImage(rotated, Offset(19, 52), fillPaint);

    return pictureRecorder.endRecording().toImage(frame.width, frame.height);
  }

  Future<ui.Image> cropImage(ui.Image image, int width, int height) {
    var pictureRecorder = ui.PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);

    Paint fillPaint = Paint();

    double offsetX = (image.width - width) / 2.0;
    double offsetY = (image.height - height) / 2.0;

    Rect srcRect =
        Rect.fromLTWH(offsetX, offsetY, width.toDouble(), height.toDouble());
    Rect dstRect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    canvas.drawImageRect(image, srcRect, dstRect, fillPaint);

    return pictureRecorder.endRecording().toImage(width, height);
  }

  Future<ui.Image> scaleImage(ui.Image image, double scale) {
    var pictureRecorder = ui.PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);

    Paint fillPaint = Paint();

    Rect srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    Rect dstRect =
        Rect.fromLTWH(0, 0, image.width * scale, image.height * scale);
    canvas.drawImageRect(image, srcRect, dstRect, fillPaint);

    return pictureRecorder
        .endRecording()
        .toImage((image.width * scale).round(), (image.height * scale).round());
  }

  Size rotatedSize(int rw, int rh, double radians) {
    var x1 = -rw / 2,
        x2 = rw / 2,
        x3 = rw / 2,
        x4 = -rw / 2,
        y1 = rh / 2,
        y2 = rh / 2,
        y3 = -rh / 2,
        y4 = -rh / 2;

    var x11 = x1 * cos(radians) + y1 * sin(radians),
        y11 = -x1 * sin(radians) + y1 * cos(radians),
        x21 = x2 * cos(radians) + y2 * sin(radians),
        y21 = -x2 * sin(radians) + y2 * cos(radians),
        x31 = x3 * cos(radians) + y3 * sin(radians),
        y31 = -x3 * sin(radians) + y3 * cos(radians),
        x41 = x4 * cos(radians) + y4 * sin(radians),
        y41 = -x4 * sin(radians) + y4 * cos(radians);

    var xMin = [x11, x21, x31, x41].reduce(min);
    var xMax = [x11, x21, x31, x41].reduce(max);

    var yMin = [y11, y21, y31, y41].reduce(min);
    var yMax = [y11, y21, y31, y41].reduce(max);

    return Size(xMax - xMin, yMax - yMin);
  }

  Future<ui.Image> rotatedImage(ui.Image image, double angle) {
    var pictureRecorder = ui.PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);

    Size size = rotatedSize(image.width, image.height, angle);
//    canvas.drawRect(
//        Rect.fromLTWH(0, 0, size.width.toDouble(), size.height.toDouble()),
//        Paint()..color = Colors.blue);

    double r = sqrt(pow(size.width, 2) + pow(size.height, 2));
    double startAngle = atan(size.height / size.width);
    Point p0 = Point(r * cos(startAngle), r * sin(startAngle));
    double xAngle = angle;
    Point px =
        Point(r * cos(xAngle + startAngle), r * sin(xAngle + startAngle));
    canvas.translate((p0.x - px.x) / 2, (p0.y - px.y) / 2);
    canvas.rotate(xAngle);

//    Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
//    Rect dst = Rect.fromCircle(
//        center: Offset(size.width / 2, size.height / 2), radius: max / 2);
//    canvas.drawImageRect(image, src, dst, Paint());
    canvas.drawImage(
        image,
        Offset(
            (size.width - image.width) / 2, (size.height - image.height) / 2),
        Paint());

    return pictureRecorder
        .endRecording()
        .toImage((size.width).round(), (size.height).round());
  }

  double _calculateScale(Size srcSize, Size destSize) {
    if (srcSize == null || destSize == null) {
      return 1.0;
    }

    double iRatio = srcSize.width / srcSize.height;
    double cRatio = destSize.width / destSize.height;

    double ratio = 1.0;
    if (iRatio > cRatio) {
      ratio = destSize.height / srcSize.height;
    } else {
      ratio = destSize.width / srcSize.width;
    }

    return ratio;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: new FutureBuilder<List<Photo>>(
        future: _fetchPhotos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);

          return snapshot.hasData
              ? new PhotosGridView(
                  photos: snapshot.data, controller: _faceScrollController)
              : new Center(child: new CircularProgressIndicator());
        },
      ),
      floatingActionButton: SpeedDial(
          // both default to 16
          marginRight: 24,
          marginBottom: 24,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: IconThemeData(size: 22.0),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          children: [
            SpeedDialChild(
                child: Icon(Icons.add_a_photo),
                backgroundColor: primaryColor,
                label: 'Add Photo',
                labelStyle: TextStyle(fontSize: 16.0),
                onTap: _takePicture),
            SpeedDialChild(
                child: Icon(Icons.image),
                backgroundColor: primaryColor,
                label: 'Generate',
                labelStyle: TextStyle(fontSize: 16.0),
                onTap: _generate),
          ]), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
