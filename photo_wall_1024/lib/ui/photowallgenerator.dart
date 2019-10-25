import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:photo_wall_1024/database/database.dart';
import 'package:photo_wall_1024/development/logger.dart';

class Frame {
  String file;

  double scale;
  double angle;
  Offset offset;

  ui.Image _frameImageCache;

  Frame(this.file, this.scale, this.angle, this.offset);

  Future<ui.Image> getImage() async {
    if (_frameImageCache == null) {
      _frameImageCache = await _loadFrame(file);
    }

    return _frameImageCache;
  }

  Future<ui.Image> _loadFrame(String frameFile) async {
    Logger.debug("loading frame from ... [$frameFile]");

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
}

class PhotoWallGenerator {

  List<Photo> _photos;
  List<Frame> _frames;

  void addFrame(String file, double scale, double angle, Offset offset) {

  }

}