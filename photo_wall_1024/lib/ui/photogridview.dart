import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_wall_1024/database/database.dart';

class PhotosGridView extends StatelessWidget {
  final List<Photo> photos;
  final ScrollController controller;

  PhotosGridView({Key key, this.photos, this.controller}) : super(key: key);

  Widget getPhotoGridCell(BuildContext context, Photo face) {
    if (face is PhotoPlaceHolder) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GestureDetector(
        onTap: () {
        },
        child: new Card(
          elevation: 3.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Stack(children: [
                Positioned.fill(
                  child: Image.file(File(face.file), fit: BoxFit.cover),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new GridView.count(
      controller: controller,
      crossAxisCount: 2,
      childAspectRatio: .75,
      children: List.generate(photos.length, (index) {
        return getPhotoGridCell(context, photos[index]);
      }),
    );
  }
}
