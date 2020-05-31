import 'dart:io';
import '../../vidlib.dart';

// Represents a video whose content has been saved to the file system
class VideoFile {
  Video video;
  File file;

  VideoFile(this.video, this.file);
}
