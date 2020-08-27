import 'dart:io';
import '../../vidlib.dart';

// Represents media whose content has been saved to the file system
class MediaFile {
  Media media;
  File file;

  MediaFile(this.media, this.file);
}
