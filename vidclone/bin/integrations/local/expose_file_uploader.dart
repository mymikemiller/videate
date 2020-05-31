// import 'package:vidlib/src/models/video_file.dart';
// import 'package:vidlib/src/models/served_video.dart';
// import 'package:path/path.dart' as p;
// import '../../uploader.dart';

// // Does not upload the file, instead returns a VideoAtUri with the uri set to
// // the file's path with the localDirectory replaced with the hostedDirectory.
// class ExposeFileUploader extends Uploader {
//   @override
//   String get id => 'expose_file';

//   final String localDirectory;
//   final String hostedDirectory;

//   ExposeFileUploader(this.localDirectory, this.hostedDirectory);

//   @override
//   Future<ServedVideo> upload(VideoFile videoFile) {
//     final uri = getDestinationUri(p.basename(videoFile.file.path));
//     final servedVideo = ServedVideo((b) => b
//       ..video = videoFile.video.toBuilder()
//       ..uri = uri
//       ..lengthInBytes = videoFile.file.lengthSync());
//     return Future.value(servedVideo);
//   }

//   @override
//   Uri getDestinationUri(String fileName) {
//     if (videoFile == null) {
//       throw 'videoFile must be specified. ExposeFileUploader cannot compute a destination URI from only a fileName.';
//     }
//     final path =
//         videoFile.file.path.replaceFirst(localDirectory, hostedDirectory);

//     return Uri(path: path);
//   }
// }
