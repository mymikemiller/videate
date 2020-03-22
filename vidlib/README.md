A library common to Videate applications

## Usage

A simple usage example:

```dart
import 'package:vidlib/vidlib.dart';

main() {
  var video = new Video(...);
  print('Video: ${video.title}');
}
```

## Development

### Models

This library uses the json_serializable package to generate code for serializing to and deserializing from json. After modifying a model file (e.g. video.dart) you must run the following command to update the json serialization code file (e.g. video.g.dart):

```dart
pub run build_runner build
```

Alternatively, run this command in the background to have the generated files automatically update when changes are detected:

```dart
pub run build_runner watch
```