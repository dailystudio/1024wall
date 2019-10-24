import 'package:path/path.dart';
import 'package:photo_wall_1024/development/logger.dart';
import 'package:sqflite/sqflite.dart';

final String tableFaces = "photos";
final String tableFacesTemp = "_photos_temp";

class Photo {
  int id;
  String file;
  int timestamp;
  String name;

  Photo();

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'file': file,
      'name': name,
      'timestamp': timestamp,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    Photo photo = new Photo();

    photo.id = map['id'];
    photo.file = map['file'];
    photo.timestamp = map['timestamp'];
    photo.name = map['name'];

    return photo;
  }

  @override
  String toString() {
    // TODO: implement toString
    return "photo: file = [${basename(file)}]";
  }
}

class PhotoPlaceHolder extends Photo {
  PhotoPlaceHolder() {
    file = "";
  }
}

final initialScript = [];

final migrations = [
  '''
  ALTER TABLE $tableFaces ADD COLUMN reviewed INTEGER DEFFAULT 0;
  '''
];

class PhotoDatabase {
  Database database;

  Future<void> open() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'faces.db'),
      onCreate: (Database db, int version) async {
        Logger.debug('creating the database..., version = $version');
        await db.execute(
            '''
            CREATE TABLE $tableFaces (
                id INTEGER PRIMARY KEY AUTOINCREMENT, 
                file TEXT UNIQUE NOT NULL, 
                timestamp INTEGER NOT NULL,
                name TEXT
            );
            '''
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        Logger.debug('upgrading the database..., oldVersion = $oldVersion, newVersion = $newVersion');
      },
      version: 1,
    );
  }

  Future<int> addPhoto(Photo face) async {
    if (database == null || !database.isOpen) {
      Logger.debug('call open() first');

      return -1;
    }

    Map<String, dynamic> values = face.toMap();
    Logger.debug('new photo object: $values');

    try {
      face.id = await database.insert(
        tableFaces,
        face.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger.debug('add photo failed: $e');
      face.id = -1;
    }

    Logger.debug('new photo id: ${face.id}');

    return face.id;
  }

  Future<List<Photo>> listPhotos() async {
    if (database == null || !database.isOpen) {
      Logger.debug('call open() first');

      return null;
    }

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await database.query(tableFaces);

    List<Photo> faces;

    try {
      faces = List.generate(maps.length, (i) {
        return new Photo.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.debug('list photos failed: $e');

      faces = null;
    }

    if (faces != null) {
      faces.sort((a, b) {
        return -(a.timestamp - b.timestamp);
      });
    }

    return faces;
  }

  Future<Photo> getPhoto(int id) async {
    if (database == null || !database.isOpen) {
      Logger.debug('call open() first');

      return null;
    }

    List<Map> maps;
    try {
      maps = await database.query(tableFaces, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      Logger.debug('get photo failed: $e');

      maps = null;
    }

    if (maps != null && maps.length > 0) {
      return new Photo.fromMap(maps.first);
    }

    return null;
  }

  Future<int> update(Photo photo) async {
    if (database == null || !database.isOpen) {
      Logger.debug('call open() first');

      return 0;
    }

    if (photo.id <= 0) {
      Logger.debug('photo.id should not be empty.');

      return 0;
    }

    return await database.update(tableFaces, photo.toMap(),
        where: 'id = ?', whereArgs: [photo.id]);
  }

  Future<void> close() async {
    if (database == null || !database.isOpen) {
      Logger.debug('call open() first');

      return null;
    }

    try {
      await database.close();
    } catch (e) {
      Logger.debug('close db failed: $e');
    }
  }
}
