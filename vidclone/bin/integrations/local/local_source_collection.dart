import 'package:vidlib/vidlib.dart';

import '../../source_collection.dart';

class LocalSourceCollection extends SourceCollection {
  LocalSourceCollection(String directoryPath) : super(directoryPath);

  @override
  Platform get platform => Platform(
        (p) => p
          ..id = 'local_folder'
          ..uri = Uri.parse(''),
      );

  @override
  String get identifierMeaning => 'Directory path';
}
