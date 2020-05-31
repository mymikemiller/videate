A library common to Videate applications

## Usage

A simple usage example:

```dart
import 'package:vidlib/vidlib.dart';

main() {
  var video = Video((b) => b
    ..title = 'My Title'
    ..description = 'My Description'
    ..sourceUrl = 'https://www.example.com'
    ..sourceReleaseDate = DateTime.now().toUtc());
  print('Video: ${video.title}');
}
```

## Prerequisites

VidLib uses ffprobe to determine the duration of video media. Ffprobe can be installed along with ffmpeg.

Install ffmpeg (mac instructions using homebrew below):

```
brew install ffmpeg
```

## Development (VSCode)

Open the videate/videate.code-workspace workspace in VSCode

### Prerequisites

Get app dependencies:

```
cd vidlib
pub get
```

Build the models as described below

### Debug VidClone server

Set Run Configuration to "VidClone (vidclone)"
Start Debugging

### Debug Tests
Set Run Configuration to "VidClone (vidclone)"
Start Debugging

### Models

This library uses the json_serializable package to generate code for serializing to and deserializing from json. After modifying a model file (e.g. video.dart) you must run the following command to update the json serialization code file (e.g. video.g.dart):

```dart
pub run build_runner build
```

Alternatively, run this command in the background to have the generated files automatically update when changes are detected:

```dart
pub run build_runner watch
```

## Authors

* **Mike Miller** - *Initial work* - [mymikemiller](https://github.com/mymikemiller)